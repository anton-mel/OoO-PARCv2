import subprocess
import itertools

# Paths to simulation executables
SINGLE_CYCLE_SIM = "./imuldiv-singcyc-sim"
ITERATIVE_SIM = "./imuldiv-iterative-sim"

# Generates all possible 32-bit hex values (currently limited to 4-bit for quick testing)
def generate_hex_32bit():
    for i in range(1, 2**6):  # Change to `2**32` for full 32-bit range
        yield f"{i:08x}"  # Format as zero-padded 8-digit hex

# Extract the result from simulator output
def parse_output(output):
    lines = output.split("\n")
    for line in lines:
        if "=" in line:  # Match both multiplication and division results
            parts = line.split("=")
            if len(parts) == 2:
                result = parts[-1].strip()
                return result.lstrip("0x") or "0"  # Normalize format, ensuring "0" if empty
    return None

# Runs a simulation and gets the result
def run_simulator(simulator, a, b):
    cmd = [simulator, f"+op=div", f"+a={a}", f"+b={b}"]
    process = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return parse_output(process.stdout)

# Print in color
def print_colored(message, color):
    colors = {
        'red': '\033[91m',  # Red
        'green': '\033[92m',  # Green
        'reset': '\033[0m',  # Reset to default color
    }
    print(f"{colors[color]}{message}{colors['reset']}")

# Test all pairs of hex values
def main():
    matches = 0
    errors = 0
    for a, b in itertools.product(generate_hex_32bit(), repeat=2):  # Iterate over 4-bit range for quick testing
        result_single = run_simulator(SINGLE_CYCLE_SIM, a, b)
        result_iterative = run_simulator(ITERATIVE_SIM, a, b)

        if result_single is None or result_iterative is None:
            print_colored(f"[ERROR] Missing output for a={a}, b={b}", 'red')
            continue

        # Ensure numeric equivalence, ignoring formatting
        val_single = int(result_single, 16)
        val_iterative = int(result_iterative, 16)

        if val_single != val_iterative:
            print_colored(f"[MISMATCH] a={a}, b={b}", 'red')
            print(f"  Single-cycle  : {result_single} (decimal: {val_single})")
            print(f"  Iterative     : {result_iterative} (decimal: {val_iterative})")
            errors += 1
        else:
            print_colored(f"[MATCH] a={a}, b={b}", 'green')
            print(f"  Single-cycle  : {result_single} (decimal: {val_single})")
            print(f"  Iterative     : {result_iterative} (decimal: {val_iterative})")
            matches += 1

    print(f"\nTotal matches: {matches}")
    print(f"Total mismatches: {errors}")

if __name__ == "__main__":
    main()
