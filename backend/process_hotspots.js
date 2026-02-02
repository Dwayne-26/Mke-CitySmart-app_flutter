const fs = require('fs');
const csv = fs.readFileSync('citations_2025.csv', 'utf8');
const lines = csv.split('\n').slice(1).filter(l => l.trim());

// Parse citations
const streetCounts = {};
const hourCounts = Array(24).fill(0);
const dayOfWeekCounts = Array(7).fill(0);
const violationCounts = {};
const hourByDayOfWeek = Array(7).fill(null).map(() => Array(24).fill(0));

lines.forEach(line => {
  const parts = line.split(',');
  if (parts.length < 5) return;
  
  const dateStr = parts[1];
  const timeStr = parts[2];
  const violation = parts[3];
  const location = parts[4];
  
  // Parse hour
  const timeParts = timeStr.match(/(\d+):(\d+):(\d+)\s*(AM|PM)/i);
  let hour = 0;
  if (timeParts) {
    hour = parseInt(timeParts[1]);
    const ampm = timeParts[4].toUpperCase();
    if (ampm === 'PM' && hour !== 12) hour += 12;
    if (ampm === 'AM' && hour === 12) hour = 0;
    hourCounts[hour]++;
  }
  
  // Parse day of week
  const dateParts = dateStr.split('/');
  if (dateParts.length === 3) {
    const d = new Date(2025, parseInt(dateParts[0])-1, parseInt(dateParts[1]));
    const dayOfWeek = d.getDay();
    if (dayOfWeek >= 0 && dayOfWeek <= 6) {
      dayOfWeekCounts[dayOfWeek]++;
      hourByDayOfWeek[dayOfWeek][hour]++;
    }
  }
  
  // Count violations
  if (violation) {
    violationCounts[violation] = (violationCounts[violation] || 0) + 1;
  }
  
  // Extract street name (simplify)
  const streetMatch = location.match(/[NSEW]\s+[\w\s]+(?:ST|AV|DR|PL|CT|BL|RD|WY|LN)/i);
  if (streetMatch) {
    const street = streetMatch[0].toUpperCase().trim();
    streetCounts[street] = (streetCounts[street] || 0) + 1;
  }
});

// Get top 100 streets
const topStreets = Object.entries(streetCounts)
  .sort((a,b) => b[1] - a[1])
  .slice(0, 100)
  .map(([street, count]) => ({ street, count }));

// Get top violations
const topViolations = Object.entries(violationCounts)
  .sort((a,b) => b[1] - a[1])
  .slice(0, 20)
  .map(([type, count]) => ({ type, count }));

// Calculate peak hours (top 6)
const peakHours = hourCounts
  .map((c,i) => ({hour: i, count: c}))
  .sort((a,b) => b.count - a.count)
  .slice(0, 6)
  .map(h => h.hour);

// Calculate peak days (0=Sun, 6=Sat)
const peakDays = dayOfWeekCounts
  .map((c,i) => ({day: i, count: c}))
  .sort((a,b) => b.count - a.count)
  .slice(0, 3)
  .map(d => d.day);

// Normalize hour distribution to 0-1 scale
const maxHour = Math.max(...hourCounts);
const hourDistributionNormalized = hourCounts.map(c => parseFloat((c / maxHour).toFixed(3)));

// Normalize day distribution
const maxDay = Math.max(...dayOfWeekCounts);
const dayDistributionNormalized = dayOfWeekCounts.map(c => parseFloat((c / maxDay).toFixed(3)));

const output = {
  generatedAt: new Date().toISOString(),
  totalCitations: lines.length,
  hourDistribution: hourCounts,
  hourDistributionNormalized,
  dayOfWeekDistribution: dayOfWeekCounts,
  dayOfWeekNames: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  dayDistributionNormalized,
  hourByDayOfWeek,
  topStreets,
  topViolations,
  peakHours,
  peakDays,
  // Risk multipliers for algorithm
  riskMultipliers: {
    hours: hourDistributionNormalized,
    days: dayDistributionNormalized
  }
};

fs.writeFileSync('citation_hotspots.json', JSON.stringify(output, null, 2));
console.log('Generated citation_hotspots.json');
console.log('Total citations:', lines.length);
console.log('Peak hours:', peakHours);
console.log('Peak days:', peakDays.map(d => output.dayOfWeekNames[d]));
console.log('Top 5 streets:', topStreets.slice(0, 5).map(s => s.street));
console.log('Top 5 violations:', topViolations.slice(0, 5).map(v => v.type));
