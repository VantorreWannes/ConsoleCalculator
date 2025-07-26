# ConsoleCalculator

A simple yet powerful command-line calculator written in Zig. This calculator supports a wide range of mathematical operations, including complex numbers, and follows the standard order of operations.

## Features

- **Standard Arithmetic**: Addition, subtraction, multiplication, and division.
- **Exponents**: Use the `^` operator for exponentiation.
- **Parentheses**: Control the order of operations with `()`.
- **Complex Numbers**: Full support for complex number arithmetic, including `i` for the imaginary unit.
- **Mathematical Functions**: A rich set of built-in functions:
  - `sqrt`, `log`, `ln`, `lb`, `exp`
  - `sin`, `cos`, `tan`, `asin`, `acos`, `atan`
  - `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh`
  - `abs`, `conj`, `re`, `im`, `floor`, `ceil`, `gamma`
- **Constants**: Pre-defined mathematical constants:
  - `e`, `pi`, `phi`, `tau`

## Usage

To use the calculator, run the program from your terminal and pass the mathematical expression as a command-line argument.

### Building the Calculator

To build the calculator, you need to have the Zig compiler installed. Then, you can use the following command:

```bash
zig build
```

### Running the Calculator

Once built, you can run the calculator from the `zig-out/bin` directory:

```bash
./zig-out/bin/ConsoleCalculator "3 * (4 + 5^2) / -4"
```

This command will output the result of the expression `-21`.

## How It Works

The calculator is composed of two main components:

1.  **Tokenizer**: This component takes the input expression as a string and breaks it down into a sequence of tokens (e.g., numbers, operators, functions).

2.  **Parser**: The parser takes the tokens from the tokenizer and evaluates the expression using a recursive descent parsing strategy. This approach correctly handles operator precedence and associativity.

The core logic is designed to be extensible, making it easy to add new functions and operators in the future.

## Docs

You can build the docs for this project using the following command:
```bash
zig build docs
```

and you can view them using 
```bash
python -m http.server 8000 -d zig-out/docs/
```