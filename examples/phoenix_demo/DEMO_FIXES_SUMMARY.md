# Demo Fixes Summary - Paris Elixir User Group

## Important Notes

### Running the Phoenix Server
**CRITICAL**: Always run `mix phx.server` from the `examples/phoenix_demo` directory, NOT from the root `swiex` directory.

```bash
cd examples/phoenix_demo
mix phx.server
```

## Fixes Applied

### 1. Removed Duplicate Code
- **Deleted**: `examples/phoenix_demo/lib/prolog_demo/causenet_session_manager.ex` (unused duplicate)
- **Kept**: `examples/phoenix_demo/lib/prolog_demo/causal_session_manager.ex` (the one actually in use)
- This eliminates confusion about which session manager handles causal reasoning

### 2. Fixed Path Finding Algorithm
**Problem**: Paths were displayed in reverse order with duplicate start nodes
- Before: `death → lung_cancer → smoking → smoking`
- After: `smoking → lung_cancer → death`

**Solution**: Corrected the Prolog `find_paths` rule in `CausalSessionManager`:
```prolog
find_paths(Start, End, MaxDepth, Path) :- 
    find_paths_helper(Start, End, MaxDepth, [Start], RevPath), 
    reverse(RevPath, Path).

find_paths_helper(End, End, _, Visited, Visited).

find_paths_helper(Start, End, MaxDepth, Visited, Path) :- 
    MaxDepth > 0, 
    causes(Start, Next), 
    \+ member(Next, Visited), 
    MaxDepth1 is MaxDepth - 1, 
    find_paths_helper(Next, End, MaxDepth1, [Next|Visited], Path).
```

### 3. Fixed N-Queens Solver
**Problem**: N-Queens was returning 0 solutions due to using `abs` function not available in basic Prolog
**Solution**: Replaced `abs(Q - Q1) =\= D` with explicit checks:
```prolog
safe_queen(Q, [Q1|Qs], D) :-
    Q \= Q1,
    Q - Q1 =\= D,    % Check diagonal down
    Q1 - Q =\= D,    % Check diagonal up
    D1 is D + 1,
    safe_queen(Q, Qs, D1).
```

### 4. UI Improvements
- **Removed**: Search depth dropdown (not useful for demo)
- **Removed**: "(search depth: X)" text from results
- **Updated**: Loading message from "Something went wrong" to "🔄 Unification in progress. Backtracking. This may take some time..."

### 5. Performance Optimizations
- Reduced CauseNet data loading from 10,000 to 1,000 relationships
- Limited path finding results to 10 paths maximum
- Added better fallback data for smoking-related causal chains

### 6. Monitoring Integration
- Added `Swiex.Monitoring` module for tracking query statistics
- Integrated monitoring into all session managers
- Created monitoring dashboard at `/monitoring` route

## Demo Sections

### 1. Causal Reasoning (`/causenet/causal`)
- Demonstrates path finding in causal graphs
- Example queries:
  - smoking → death
  - smoking → cervical_cancer
  - obesity → death

### 2. Constraint Solving (`/causenet/constraints`)
- N-Queens puzzle solver (now working!)
- Sudoku solver

### 3. Prolog Playground (`/causenet/playground`)
- Interactive Prolog query interface
- Users can write custom Prolog queries

### 4. Monitoring Dashboard (`/monitoring`)
- Real-time query statistics
- Performance metrics for each demo section

## Testing the Fixes

1. Start the server from the correct directory:
   ```bash
   cd examples/phoenix_demo
   mix phx.server
   ```

2. Navigate to http://localhost:4000/causenet/causal

3. Test causal path finding:
   - Start: "smoking"
   - End: "death"
   - Should show paths like: `smoking → lung_cancer → death`

4. Test N-Queens:
   - Navigate to Constraint Solving tab
   - Click "Solve 8-Queens"
   - Should now show 92 solutions

## Common Issues

### Port Already in Use
```bash
# Kill existing Phoenix processes
ps aux | grep "beam.smp" | grep -v grep | awk '{print $2}' | xargs kill
```

### MQI Protocol Errors
- Usually caused by loading too much data
- Current limit of 1,000 relationships works well
- Can be adjusted in `causenet_service.ex`

## Files Modified

1. `lib/prolog_demo/causal_session_manager.ex` - Fixed path finding rules
2. `lib/prolog_demo/constraint_session_manager.ex` - Fixed N-Queens solver
3. `lib/prolog_demo/causenet_service.ex` - Reduced data loading
4. `lib/prolog_demo/causenet_data_loader.ex` - Improved sampling and fallback data
5. `lib/prolog_demo_web/live/causenet_live.ex` - UI improvements
6. `lib/prolog_demo_web/live/monitoring_live.ex` - New monitoring dashboard
7. `lib/swiex/monitoring.ex` - New monitoring module

## Deleted Files

1. `lib/prolog_demo/causenet_session_manager.ex` - Unused duplicate
