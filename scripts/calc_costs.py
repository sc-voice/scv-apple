import csv
import sys
from datetime import datetime

def read_costs_csv(filename):
  costs_data = []
  
  try:
    with open(filename, 'r') as file:
      reader = csv.reader(file)
      header = next(reader, None)
      
      for row in reader:
        if len(row) >= 10:
          timestamp = row[0]
          cost = float(row[9])
          date = timestamp[:10]
          cost_object = {
            'Date': date,
            'Cost': cost
          }
          costs_data.append(cost_object)
  
  except FileNotFoundError:
    print(f"Error: {filename} file not found")
    return []
  except Exception as e:
    print(f"Error reading file: {e}")
    return []
  
  return costs_data

def main():
  # Check if filename argument is provided
  if len(sys.argv) < 2:
    print("Usage: python script.py <filename>")
    return
  
  # Get filename from first argument
  filename = sys.argv[1]
  
  data = read_costs_csv(filename)
  
  # Create summary table with summed costs and count by date
  summary = {}
  for item in data:
    date = item['Date']
    cost = item['Cost']
    if date in summary:
      summary[date]['total_cost'] += cost
      summary[date]['count'] += 1
    else:
      summary[date] = {
        'total_cost': cost,
        'count': 1
      }
  
  # Print summary table
  print("Costs Summary by Date:")
  print("-" * 50)
  print(f"{'Date':<12} {'Cost':<15} {'Count':<10} {'RowCost':<10}")
  print("-" * 50)
  for date, stats in sorted(summary.items()):
    row_cost = stats['total_cost'] / stats['count']
    print(f"{date:<12} ${stats['total_cost']:<14,.2f} {stats['count']:<10} ${row_cost:<9.2f}")
  
  # Print total
  if data:
    total_cost = sum(item['Cost'] for item in data)
    print("-" * 50)
    print(f"Total records: {len(data)}")
    print(f"Total cost: ${total_cost:,.2f}")

if __name__ == "__main__":
  main()

