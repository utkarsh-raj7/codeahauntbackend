"""
Build a CLI tool using Click that:
1. Has a command 'greet' that takes a --name argument
2. Has a command 'count' that counts lines in a file
3. Has a --verbose flag that shows extra output
"""
import click

@click.group()
def cli():
    pass

@cli.command()
@click.option('--name', default='World', help='Name to greet')
def greet(name):
    # TODO: implement
    pass

@cli.command()
@click.argument('filename')
@click.option('--verbose', is_flag=True)
def count(filename, verbose):
    # TODO: implement
    pass

if __name__ == '__main__':
    cli()
