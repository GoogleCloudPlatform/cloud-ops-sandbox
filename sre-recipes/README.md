# SRE Recipes

SRE Recipes is a tool to help users familiarize themselves with finding the root cause of a breakage using monitoring.

## Usage

To view which active recipes exist, run the command below in this directory:

```
$ ./sandboxctl sre-recipes --help
```
To simulate a break in a specific recipe, run:
```
$ ./sandboxctl sre-recipes break <recipe_name>
```
To restore the original condition after simulating a break in a specific recipe, run:
```
$ ./sandboxctl sre-recipes restore <recipe_name>
```
To verify the root cause of the breakage in specific recipe, run:
```
$ ./sandboxctl sre-recipes verify <recipe_name>
```
To receive a hint about the root cause of the breakage, run:
```
$ ./sandboxctl sre-recipes hint <recipe_name>
```

## Contributing

To contribute a new recipe, you can either:

1. Create a simple config based SRE Recipe (Recommended)
    
   See `recipes/configs_based/README.md` for contribution instruction and usage.

2. Create a implementation based SRE Recipe class
    
   See `recipes/impl_based/README.md` for contribution instruction and usage.