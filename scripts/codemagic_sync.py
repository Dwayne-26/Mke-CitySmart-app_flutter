#!/usr/bin/env python3
"""
Sync Firebase secrets to Codemagic via its REST API.

Usage:
  python scripts/codemagic_sync.py \
    --app-id <CODEMAGIC_APP_ID> \
    --token <CODEMAGIC_API_TOKEN> \
    --env-file .env.firebase \
    --android-json android/app/google-services.json \
    --ios-plist ios/Runner/GoogleService-Info.plist

The script:
  1. Reads the .env file and uploads it as a secure environment variable
     FIREBASE_ENV_FILE.
  2. Base64-encodes the native config files and stores them as secure variables
     ANDROID_GOOGLE_SERVICES_JSON / IOS_GOOGLE_SERVICE_INFO_PLIST.
"""
from __future__ import annotations

import argparse
import base64
import json
import pathlib
import sys
from typing import Dict

import urllib.request

API_ROOT = "https://api.codemagic.io/apps"


def request(method: str, url: str, token: str, payload: Dict[str, str]) -> None:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "x-auth-token": token,
            "Content-Type": "application/json",
        },
        method=method,
    )
    with urllib.request.urlopen(req) as resp:  # nosec B310
        body = resp.read()
        if resp.status >= 300:
            raise RuntimeError(f"Codemagic API error {resp.status}: {body.decode()}")


def encode_file(path: pathlib.Path) -> str:
    data = path.read_bytes()
    return base64.b64encode(data).decode("ascii")


def upsert_variable(app_id: str, token: str, name: str, value: str) -> None:
    url = f"{API_ROOT}/{app_id}/environment-variables"
    payload = {"name": name, "value": value, "secure": True}
    request("POST", url, token, payload)
    print(f"✔ Updated {name}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Codemagic secret sync")
    parser.add_argument("--app-id", required=True, help="Codemagic app ID")
    parser.add_argument("--token", required=True, help="Codemagic API token")
    parser.add_argument("--env-file", required=True, type=pathlib.Path)
    parser.add_argument("--android-json", required=True, type=pathlib.Path)
    parser.add_argument("--ios-plist", required=True, type=pathlib.Path)
    args = parser.parse_args(argv)

    if not args.env_file.exists():
        print(f"Missing env file: {args.env_file}", file=sys.stderr)
        return 1
    for path in (args.android_json, args.ios_plist):
        if not path.exists():
            print(f"Missing config: {path}", file=sys.stderr)
            return 1

    env_contents = args.env_file.read_text(encoding="utf-8")
    android_b64 = encode_file(args.android_json)
    ios_b64 = encode_file(args.ios_plist)

    upsert_variable(args.app_id, args.token, "FIREBASE_ENV_FILE", env_contents)
    upsert_variable(
        args.app_id, args.token, "ANDROID_GOOGLE_SERVICES_JSON", android_b64
    )
    upsert_variable(
        args.app_id, args.token, "IOS_GOOGLE_SERVICE_INFO_PLIST", ios_b64
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
