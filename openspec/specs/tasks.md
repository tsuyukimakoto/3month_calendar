# Tasks: 3-Month Calendar macOS Widget

## Phase 1: Foundation & UI
1. Set up widget project structure and baseline widget target
2. Implement 3-month date model (prev/current/next) with week-start switch
3. Render basic calendar grid for one month (no styling)
4. Compose 3-month view using Preset A (3-up horizontal)
5. Add month/weekday English labels with auto full/short selection

## Phase 2: Layout Presets & Styling
1. Implement Preset B (current month emphasized)
2. Implement Preset C (current month full width)
3. Implement Preset D (stacked compact)
4. Add color theming for weekdays and holidays
5. Add visual emphasis for current month

## Phase 3: Settings & Actions
1. Add settings for week start (Sunday/Monday)
2. Add settings for layout preset (A/B/C/D), default A
3. Add settings for weekday colors and holiday color
4. Add settings for month/weekday label style (auto/full/short)
5. Add on-click action options:
   - Open Calendar app
   - Open Google Calendar in default browser
   - Do nothing

## Phase 4: Holidays & Caching
1. Implement holiday fetch via public iCal URL
2. Add default Japan holiday iCal URL
3. Add holiday source URL override setting
4. Cache holidays locally by year
5. Refresh cache at start of month to include next year
6. Fallback to cached data on fetch failure

## Phase 5: QA & Polish
1. Verify layout in 2-column widget size
2. Confirm label auto-sizing in tight/roomy layouts
3. Validate holiday coloring and weekend coloring
4. Verify click action behavior across options
5. Add basic error logging for holiday fetch
