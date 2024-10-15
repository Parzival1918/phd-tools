import marimo

__generated_with = "0.9.4"
app = marimo.App(width="medium")


@app.cell
def __():
    import marimo as mo
    from pathlib import Path
    import pandas as pd
    import altair as alt
    from ase.visualize import view
    import ase.io as asio
    from shelxfile import Shelxfile
    import tempfile
    return Path, Shelxfile, alt, asio, mo, pd, tempfile, view


@app.cell
def __(mo):
    struct_loc = mo.ui.text(placeholder="structures.csv...", label="Enter path of 'structures.csv':")
    struct_dir = mo.ui.text(placeholder="structures/...", label="Enter path of 'structures' dir:")
    struct_loc, struct_dir
    return struct_dir, struct_loc


@app.cell
def __(Path, mo, struct_loc):
    mo.stop(struct_loc.value is None or struct_loc.value is "")
    print(struct_loc.value)
    struct_file = Path(struct_loc.value).expanduser()
    print(struct_file)

    mo.stop(not struct_file.exists())
    return (struct_file,)


@app.cell
def __(Path, mo, struct_dir):
    mo.stop(struct_dir.value is None or struct_dir.value is "")
    print(struct_dir.value)
    rootDir = Path(struct_dir.value).expanduser()
    print(rootDir)

    mo.stop(not rootDir.exists())
    return (rootDir,)


@app.cell
def __(alt, mo, pd, struct_file):
    df = pd.read_csv(struct_file)

    x, y = df["density"], df["energy"]
    _chart = (
        alt.Chart(df).mark_point().encode(
            x="density",
            y="energy",
            color="spacegroup"
        )
    )
    chart = mo.ui.altair_chart(_chart)

    chart
    return chart, df, x, y


@app.cell
def __(chart, mo):
    table = mo.ui.table(chart.value, selection="single")
    table
    return (table,)


@app.cell
def __(Path, mo, rootDir, table):
    mo.stop(table.value.empty)
    selection = table.value
    file_path = rootDir / (selection.iloc[0]["id"] + ".res")
    file_path = Path("~/downloads/PYRENE01.xyz").expanduser()

    #shx = Shelxfile()
    #shx.read_file(file_path)
    #with tempfile.TemporaryDirectory() as temp_dir:
    #    print(temp_dir)
    #    shx.to_cif(temp_dir + "/temp.cif")
    #    print(Path(temp_dir + "/temp.cif").read_text())
    #    atoms = asio.read(temp_dir + "/temp.cif")
    return file_path, selection


if __name__ == "__main__":
    app.run()
