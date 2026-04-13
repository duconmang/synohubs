/**
 * NAS Model Image Mapper
 * 
 * Maps Synology model names to their device images.
 * Images are stored in src/assets/nas_models/
 * 
 * Model names from DSM API come as: "DS918+", "DS1821+", "DS220+", etc.
 * Image files are named: DS918plus.png, DS1821plus.png, DS220plus.png, etc.
 */

// Import all NAS model images
const nasImages = import.meta.glob('../assets/nas_models/*.png', { eager: true, query: '?url', import: 'default' });

/**
 * Get the image URL for a NAS model.
 * Handles model name normalization (e.g., "DS918+" → "DS918plus")
 * with multi-level fallback matching.
 */
export function getNasModelImage(model: string | undefined): string | null {
  if (!model) return null;

  // Normalize: "DS918+" → "DS918plus", "DS1823xs+" → "DS1823xsplus"
  const normalized = model
    .trim()
    .replace(/\+/g, 'plus')
    .replace(/\s+/g, '');

  // Helper: find image by filename (case-insensitive)
  const findImage = (search: string): string | null => {
    for (const [path, url] of Object.entries(nasImages)) {
      const filename = path.split('/').pop()?.replace('.png', '') || '';
      if (filename.toLowerCase() === search.toLowerCase()) {
        return url as string;
      }
    }
    return null;
  };

  // 1. Exact match: "DS3617xs" → DS3617xs.png
  const exact = findImage(normalized);
  if (exact) return exact;

  // 2. Without "plus" suffix: "DS1517plus" → try "DS1517"
  if (normalized.endsWith('plus')) {
    const base = findImage(normalized.replace(/plus$/, ''));
    if (base) return base;
  }

  // 3. Partial match: model string contains a known filename
  for (const [path, url] of Object.entries(nasImages)) {
    const filename = path.split('/').pop()?.replace('.png', '') || '';
    if (normalized.toLowerCase().includes(filename.toLowerCase()) && filename.length > 3) {
      return url as string;
    }
  }

  // 4. Series fallback: "DS3617xs" → find any DS36xx image
  const seriesMatch = normalized.match(/^(DS|RS)(\d{2})/i);
  if (seriesMatch) {
    const prefix = seriesMatch[1] + seriesMatch[2];
    for (const [path, url] of Object.entries(nasImages)) {
      const filename = path.split('/').pop()?.replace('.png', '') || '';
      if (filename.toUpperCase().startsWith(prefix.toUpperCase())) {
        return url as string;
      }
    }
  }

  return null;
}

/**
 * Get a list of all available NAS model names (for dropdown/search).
 */
export function getAllNasModels(): string[] {
  return Object.keys(nasImages).map((path) => {
    const filename = path.split('/').pop()?.replace('.png', '') || '';
    return filename.replace('plus', '+');
  });
}

/**
 * Get a default/generic NAS icon color based on model series.
 */
export function getNasSeriesColor(model: string | undefined): string {
  if (!model) return 'var(--color-accent)';
  const m = model.toUpperCase();
  if (m.includes('DS36') || m.includes('DS38') || m.includes('DS24') || m.includes('DS18')) {
    return '#E3B23C'; // Gold for rack/enterprise
  }
  if (m.includes('DS15') || m.includes('DS16')) {
    return '#4ADE80'; // Green for mid-range
  }
  if (m.includes('DS9') || m.includes('DS7') || m.includes('DS4')) {
    return '#60A5FA'; // Blue for prosumer
  }
  return '#A78BFA'; // Purple for personal
}
