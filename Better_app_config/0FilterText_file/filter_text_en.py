#!/usr/bin/env python3

# Import necessary modules
import os
import sys

# Define ANSI escape sequences for colors
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"

# Define a function to filter the list
def filter(source_list_path, exclusion_list_path):
    """
    Function Description: Filter a list, excluding strings from the exclusion list.
    :param source_list_path: Path to the source list file, containing strings to be filtered.
    :param exclusion_list_path: Path to the exclusion list file, containing strings to be excluded from the source list.
    :return: The filtered list of strings.
    :raises FileNotFoundError: If the file does not exist.
    :raises ValueError: If there is an error reading the file.
    """
    # Check if the exclusion list file exists or is empty, if so, print a warning message
    if not os.path.exists(exclusion_list_path) or os.path.getsize(exclusion_list_path) == 0:
        print(f"{YELLOW}Warning: The exclusion list file '{exclusion_list_path}' does not exist or is empty.{RESET}")
        exclusion_list = set()
    else:
        try:
            # Attempt to open the exclusion list file and read the strings
            with open(exclusion_list_path, 'r') as bl_file:
                exclusion_list = {line.strip() for line in bl_file if line.strip() and not line.strip().startswith('#')}
        except Exception as e:
            # If there is an error reading the exclusion list file, print the error message and exit
            print(f"{RED}Error: An error occurred while reading the exclusion list file '{exclusion_list_path}': {e}{RESET}")
            sys.exit(1)

    try:
        # Attempt to open the source list file and read the strings
        with open(source_list_path, 'r') as app_file:
            apps = [line.strip() for line in app_file if line.strip() and not line.strip().startswith('#')]
            # If the source list file is empty after filtering, print a warning message and exit
            if not apps:
                print(f"{YELLOW}Warning: The file '{source_list_path}' is empty after filtering.{RESET}")
                sys.exit(1)
    except FileNotFoundError:
        # If the source list file does not exist, print an error message and exit
        print(f"{RED}Error: The source list file '{source_list_path}' does not exist.{RESET}")
        sys.exit(1)
    except Exception as e:
        # If there is an error reading the source list file, print the error message and exit
        print(f"{RED}Error: An error occurred while reading the source list file '{source_list_path}': {e}{RESET}")
        sys.exit(1)

    # Filter the source list, excluding the strings in the exclusion list
    filtered_apps = [app for app in apps if app not in exclusion_list and not app.isspace()]

    # If the filtered source list is empty, print a warning message
    if not filtered_apps:
        print(f"{YELLOW}Warning: No strings were filtered out.{RESET}")

    # Print the filtered source list
    for app in filtered_apps:
        print(app)

# Define the handling method when called directly by a non-python method
if __name__ == "__main__":
    # Check if the number of command-line arguments is correct, if not, exit directly
    if len(sys.argv) != 3:
        print(f"{BLUE}Usage: <filename> <source_list_path> <exclusion_list_path>{RESET}")
        sys.exit(1)

    # Get the source list file path and the exclusion list file path
    source_list_path = sys.argv[1]
    exclusion_list_path = sys.argv[2]

    # Call the filtering function
    filter(source_list_path, exclusion_list_path)