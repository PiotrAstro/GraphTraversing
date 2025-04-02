# Graph Traversal Algorithms for Public Transport Optimization

This repository contains an implementation of graph-based algorithms for optimizing public transport routes in Julia. The implementation includes Dijkstra's algorithm, A* search, and Tabu Search metaheuristic with different optimization criteria.

## Features

- **Multiple optimization criteria**: Optimize for travel time or number of transfers
- **Efficient algorithms**: Implementation of Dijkstra, A* with custom heuristics, and Tabu Search
- **Performance optimizations**: Caching mechanism for intermediate results in Tabu Search
- **Flexible data model**: Graph representation designed specifically for public transport networks

## Getting Started

### Prerequisites

- Julia 1.6 or newer ([download here](https://julialang.org/downloads/))

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/graph-traversing.git
   cd graph-traversing
   ```

2. Run the main file:
   ```bash
   julia run.jl
   ```
   The script will automatically download and install all required dependencies.

## Usage

run.jl provides good Command Line User Interface:
```
C:\Graph_Traversing> julia run.jl
  Activating project at `C:\Graph_Traversing`
Loading data from C:\Graph_Traversing\data\connection_graph.csv
Data loaded


--------------------------------------------------


What would you like to do?
        "single" -> Find a path
        "many" -> Find multiple paths
        "exit" -> end the programm
        >>> single
Enter the algorithm:
        1 or "dijkstra" -> Dijkstra's algorithm
        2 or "a_star" -> A* algorithm
        >>> dijkstra
Using Dijkstra's algorithm
Using time mode
Enter the time in format HH:MM
        >>> 12:00
Enter the stops separated by semicolons:
        >>> Okrzei;DWORZEC GŁÓWNY


Result:
Time taken: 0.01 seconds
Ride: Okrzei -> DWORZEC GŁÓWNY
Cost: 23.0 time: 0h 23min 12:04 -> 12:23
        line 145 from "Okrzei" at 12:04 to "DWORZEC GŁÓWNY" at 12:23


Press Enter to continue...
```

## Algorithm Details

### Dijkstra & A*
Both algorithms are adapted for public transport optimization with:
- Custom cost functions for time and transfers optimization
- For transfer optimization, all equivalent routes are stored
- A* uses distance-based heuristics (assuming 15 km/h average speed)

### Tabu Search
Optimizes visits to multiple stops with:
- Result caching for rapid computation
- Neighborhood generation by swapping stop pairs
- Aspiration criteria to escape local minima

## Project Structure

- `/src`: Source code files
  - `_construction.jl`: Graph construction from CSV data
  - `_graphs.jl`: Main data structures and interfaces
  - `_dijkstra.jl`: Dijkstra's algorithm implementation
  - `_a_star.jl`: A* algorithm implementation
  - `_tabu_search.jl`: Tabu Search metaheuristic
- `/data`: Place to puts ample connection graph data
- `run.jl`: Main entry point

## Why Julia?

Julia was chosen for its:
- Dynamic typing with optional type annotations
- Performance comparable to C with Python-like syntax
- Just-in-time (JIT) compilation
- Scientific computing focus

## License

This project is licensed under the MIT License.