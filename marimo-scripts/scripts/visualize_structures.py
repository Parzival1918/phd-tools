import marimo

__generated_with = "0.9.4"
app = marimo.App(width="medium")


@app.cell
def __():
    import marimo as mo
    from pathlib import Path
    import pandas as pd
    import altair as alt
    import tempfile
    return Path, alt, mo, pd, tempfile


@app.cell
def __(mo):
    file_input = mo.ui.file(filetypes=[".csv"], multiple=False, kind="area", label="Open a structures.csv file")
    file_input
    return (file_input,)


@app.cell
def __(Path, file_input, pd, tempfile):
    with tempfile.TemporaryDirectory() as dir:
        file = Path(dir + "/data.csv")
        file.write_bytes(file_input.contents())
        df = pd.read_csv(file)
    return df, dir, file


@app.cell
def __(df, mo):
    groups = ["spacegroup", "density", "energy", "minimization_step", "minimization_time"]
    group_select = mo.ui.dropdown(options=groups, label="Group by: ", value="spacegroup")

    N = max(df["minimization_step"])
    min_step_select= mo.ui.number(start=0, step=1, stop=N, label="Minimization step filter")

    mo.vstack([group_select, min_step_select])
    return N, group_select, groups, min_step_select


@app.cell
def __(alt, df, group_select, min_step_select, mo):
    if min_step_select.value == 0:
        sec = df
    else:
        sec = df[df["minimization_step"] == min_step_select.value]
        
    _chart = (
        alt.Chart(sec).mark_point().encode(
            alt.X("density").scale(zero=False, padding=2.0),
            y="energy",
            color=group_select.value
        )
    )
    chart = mo.ui.altair_chart(_chart)
    return chart, sec


@app.cell
def __(chart):
    chart
    return


@app.cell
def __(chart, mo):
    table = mo.ui.table(chart.value)
    table
    return (table,)


if __name__ == "__main__":
    app.run()
