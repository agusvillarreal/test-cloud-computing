#!/usr/bin/env python3
"""
Scheduling Algorithms Visualizer
Educational tool for understanding different scheduling policies
"""

import matplotlib.pyplot as plt
import numpy as np
from collections import deque
import argparse

class Process:
    def __init__(self, pid, arrival_time, burst_time):
        self.pid = pid
        self.arrival_time = arrival_time
        self.burst_time = burst_time
        self.remaining_time = burst_time
        self.completion_time = 0
        self.turnaround_time = 0
        self.waiting_time = 0
        self.response_time = 0
        self.first_run = -1
        
    def reset(self):
        """Reset process state for new simulation"""
        self.remaining_time = self.burst_time
        self.completion_time = 0
        self.turnaround_time = 0
        self.waiting_time = 0
        self.response_time = 0
        self.first_run = -1

class SchedulerSimulator:
    def __init__(self, processes):
        self.original_processes = processes
        self.processes = []
        self.timeline = []
        
    def reset_processes(self):
        """Reset all processes to initial state"""
        self.processes = []
        for p in self.original_processes:
            new_process = Process(p.pid, p.arrival_time, p.burst_time)
            self.processes.append(new_process)
        self.timeline = []
    
    def calculate_metrics(self):
        """Calculate performance metrics for all processes"""
        for process in self.processes:
            process.turnaround_time = process.completion_time - process.arrival_time
            process.waiting_time = process.turnaround_time - process.burst_time
    
    def print_results(self, algorithm_name):
        """Print detailed results"""
        print(f"\n{'='*60}")
        print(f"{algorithm_name} SCHEDULING RESULTS")
        print(f"{'='*60}")
        
        print(f"{'PID':<4} {'Arrival':<8} {'Burst':<6} {'Complete':<9} {'TAT':<6} {'WT':<6} {'RT':<6}")
        print(f"{'-'*4} {'-'*8} {'-'*6} {'-'*9} {'-'*6} {'-'*6} {'-'*6}")
        
        total_tat = total_wt = total_rt = 0
        
        for p in self.processes:
            print(f"P{p.pid:<3} {p.arrival_time:<8} {p.burst_time:<6} "
                  f"{p.completion_time:<9} {p.turnaround_time:<6} "
                  f"{p.waiting_time:<6} {p.response_time:<6}")
            total_tat += p.turnaround_time
            total_wt += p.waiting_time
            total_rt += p.response_time
        
        n = len(self.processes)
        print(f"\nAverage Turnaround Time: {total_tat/n:.2f}")
        print(f"Average Waiting Time: {total_wt/n:.2f}")
        print(f"Average Response Time: {total_rt/n:.2f}")
        
        return {
            'avg_tat': total_tat/n,
            'avg_wt': total_wt/n,
            'avg_rt': total_rt/n
        }
    
    def fifo_schedule(self):
        """First In First Out scheduling"""
        self.reset_processes()
        
        # Sort by arrival time
        self.processes.sort(key=lambda x: x.arrival_time)
        
        current_time = 0
        
        for process in self.processes:
            # Wait for process arrival
            if current_time < process.arrival_time:
                self.timeline.append(('IDLE', current_time, process.arrival_time))
                current_time = process.arrival_time
            
            # Set response time
            process.response_time = current_time - process.arrival_time
            process.first_run = current_time
            
            # Execute process
            start_time = current_time
            current_time += process.burst_time
            process.completion_time = current_time
            
            self.timeline.append((f'P{process.pid}', start_time, current_time))
        
        self.calculate_metrics()
        return self.print_results("FIFO")
    
    def sjf_schedule(self):
        """Shortest Job First scheduling"""
        self.reset_processes()
        
        current_time = 0
        completed = []
        remaining = self.processes.copy()
        
        while remaining:
            # Get available processes
            available = [p for p in remaining if p.arrival_time <= current_time]
            
            if not available:
                # No process available, advance time
                next_arrival = min(p.arrival_time for p in remaining)
                self.timeline.append(('IDLE', current_time, next_arrival))
                current_time = next_arrival
                continue
            
            # Select shortest job
            shortest = min(available, key=lambda x: x.burst_time)
            remaining.remove(shortest)
            
            # Set response time
            shortest.response_time = current_time - shortest.arrival_time
            shortest.first_run = current_time
            
            # Execute
            start_time = current_time
            current_time += shortest.burst_time
            shortest.completion_time = current_time
            
            self.timeline.append((f'P{shortest.pid}', start_time, current_time))
            completed.append(shortest)
        
        self.calculate_metrics()
        return self.print_results("SJF")
    
    def stcf_schedule(self):
        """Shortest Time to Completion First (Preemptive SJF)"""
        self.reset_processes()
        
        current_time = 0
        completed = []
        
        while len(completed) < len(self.processes):
            # Get available processes
            available = [p for p in self.processes 
                        if p.arrival_time <= current_time and p.remaining_time > 0]
            
            if not available:
                current_time += 1
                continue
            
            # Select process with shortest remaining time
            current_process = min(available, key=lambda x: x.remaining_time)
            
            # Set response time on first run
            if current_process.first_run == -1:
                current_process.first_run = current_time
                current_process.response_time = current_time - current_process.arrival_time
            
            # Execute for 1 time unit
            start_time = current_time
            current_process.remaining_time -= 1
            current_time += 1
            
            if current_process.remaining_time == 0:
                current_process.completion_time = current_time
                completed.append(current_process)
            
            # Add to timeline (merge consecutive runs of same process)
            if (self.timeline and 
                self.timeline[-1][0] == f'P{current_process.pid}' and 
                self.timeline[-1][2] == start_time):
                # Extend previous entry
                self.timeline[-1] = (self.timeline[-1][0], self.timeline[-1][1], current_time)
            else:
                self.timeline.append((f'P{current_process.pid}', start_time, current_time))
        
        self.calculate_metrics()
        return self.print_results("STCF")
    
    def rr_schedule(self, quantum=3):
        """Round Robin scheduling"""
        self.reset_processes()
        
        current_time = 0
        queue = deque()
        completed = []
        in_queue = set()
        
        # Add initial processes
        for p in self.processes:
            if p.arrival_time <= current_time:
                queue.append(p)
                in_queue.add(p.pid)
        
        while queue or len(completed) < len(self.processes):
            # Check for new arrivals
            for p in self.processes:
                if (p.arrival_time <= current_time and 
                    p.pid not in in_queue and 
                    p.remaining_time > 0):
                    queue.append(p)
                    in_queue.add(p.pid)
            
            if not queue:
                current_time += 1
                continue
            
            # Get next process
            current_process = queue.popleft()
            in_queue.remove(current_process.pid)
            
            # Set response time on first run
            if current_process.first_run == -1:
                current_process.first_run = current_time
                current_process.response_time = current_time - current_process.arrival_time
            
            # Execute for quantum or remaining time
            execution_time = min(quantum, current_process.remaining_time)
            start_time = current_time
            current_process.remaining_time -= execution_time
            current_time += execution_time
            
            self.timeline.append((f'P{current_process.pid}', start_time, current_time))
            
            # Check for new arrivals during execution
            for p in self.processes:
                if (p.arrival_time <= current_time and 
                    p.pid not in in_queue and 
                    p.remaining_time > 0 and 
                    p != current_process):
                    queue.append(p)
                    in_queue.add(p.pid)
            
            # Handle process completion or preemption
            if current_process.remaining_time == 0:
                current_process.completion_time = current_time
                completed.append(current_process)
            else:
                # Add back to queue
                queue.append(current_process)
                in_queue.add(current_process.pid)
        
        self.calculate_metrics()
        return self.print_results(f"Round Robin (Q={quantum})")
    
    def visualize_timeline(self, title="Scheduling Timeline"):
        """Create Gantt chart visualization"""
        if not self.timeline:
            print("No timeline data to visualize")
            return
        
        fig, ax = plt.subplots(figsize=(12, 6))
        
        colors = plt.cm.Set3(np.linspace(0, 1, len(self.processes) + 1))
        color_map = {'IDLE': colors[0]}
        
        for i, process in enumerate(self.processes):
            color_map[f'P{process.pid}'] = colors[i + 1]
        
        # Draw timeline
        y_pos = 1
        for task, start, end in self.timeline:
            ax.barh(y_pos, end - start, left=start, height=0.5, 
                   color=color_map.get(task, 'gray'), 
                   edgecolor='black', alpha=0.8)
            
            # Add text label
            if end - start > 1:  # Only add text if bar is wide enough
                ax.text(start + (end - start)/2, y_pos, task, 
                       ha='center', va='center', fontweight='bold')
        
        # Formatting
        ax.set_ylim(0.5, 1.5)
        ax.set_xlabel('Time')
        ax.set_title(title)
        ax.set_yticks([])
        ax.grid(True, axis='x', alpha=0.3)
        
        # Add time markers
        max_time = max(end for _, _, end in self.timeline)
        ax.set_xticks(range(0, max_time + 1, max(1, max_time // 20)))
        
        plt.tight_layout()
        plt.show()

def main():
    # Example processes
    processes = [
        Process(1, 0, 5),
        Process(2, 1, 3),
        Process(3, 2, 8),
        Process(4, 3, 6)
    ]
    
    simulator = SchedulerSimulator(processes)
    
    print("PROCESS INPUT:")
    print("PID | Arrival | Burst")
    print("----|---------|-------")
    for p in processes:
        print(f"P{p.pid}  | {p.arrival_time:<7} | {p.burst_time}")
    
    # Run all algorithms
    results = {}
    
    results['FIFO'] = simulator.fifo_schedule()
    simulator.visualize_timeline("FIFO Scheduling")
    
    results['SJF'] = simulator.sjf_schedule()
    simulator.visualize_timeline("SJF Scheduling")
    
    results['STCF'] = simulator.stcf_schedule()
    simulator.visualize_timeline("STCF Scheduling")
    
    results['RR'] = simulator.rr_schedule(3)
    simulator.visualize_timeline("Round Robin (Q=3)")
    
    # Comparison
    print(f"\n{'='*60}")
    print("ALGORITHM COMPARISON")
    print(f"{'='*60}")
    print(f"{'Algorithm':<15} {'Avg TAT':<8} {'Avg WT':<8} {'Avg RT':<8}")
    print(f"{'-'*15} {'-'*8} {'-'*8} {'-'*8}")
    
    for algo, metrics in results.items():
        print(f"{algo:<15} {metrics['avg_tat']:<8.2f} {metrics['avg_wt']:<8.2f} {metrics['avg_rt']:<8.2f}")

if __name__ == "__main__":
    main()