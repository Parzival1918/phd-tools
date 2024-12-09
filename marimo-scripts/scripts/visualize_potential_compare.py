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
    file_input1 = mo.ui.file(filetypes=[".csv"], multiple=False, kind="area", label="Open the structures.csv of database 1")
    file_input1
    return (file_input1,)


@app.cell
def __(mo):
    file_input2 = mo.ui.file(filetypes=[".csv"], multiple=False, kind="area", label="Open the structures.csv of database 2")
    file_input2
    return (file_input2,)


@app.cell
def __(mo):
    compare_file = mo.ui.file(filetypes=[".csv"], multiple=False, kind="area", label="Open the comparison file btween the databases")
    compare_file
    return (compare_file,)


@app.cell
def __(Path, compare_file, file_input1, file_input2, pd, tempfile):
    with tempfile.TemporaryDirectory() as dir:
        file = Path(dir + "/data.csv")
        file.write_bytes(file_input1.contents())
        df1 = pd.read_csv(file)

        file = Path(dir + "/data.csv")
        file.write_bytes(file_input2.contents())
        df2 = pd.read_csv(file)

        file = Path(dir + "/data.csv")
        file.write_bytes(compare_file.contents())
        compare_data = pd.read_csv(file)
    return compare_data, df1, df2, dir, file


@app.cell
def __(compare_data, df1):
    # add column to dataframes that relates structure matches between databases
    matches = {}
    for mol_id, id_matches in zip(compare_data["mol_id"], compare_data["matches"]):
        matches_list = id_matches.split("/")
        matches[mol_id] = matches_list

    df1["matches"] = df1["id"].map(matches)
    df1["match"] = df1["matches"].notnull()
    return id_matches, matches, matches_list, mol_id


@app.cell
def __(alt, df1, mo):
    _chart1 = (
        alt.Chart(df1).mark_point().encode(
            alt.X("density").scale(zero=False, padding=2.0),
            y="energy",
            color="match"
        )
    )
    chart1 = mo.ui.altair_chart(_chart1)
    return (chart1,)


@app.cell
def __(alt, df2_new, mo):
    _chart1 = (
        alt.Chart(df2_new).mark_point().encode(
            alt.X("density").scale(zero=False, padding=2.0),
            y="energy",
            color="match"
        )
    )
    chart2 = mo.ui.altair_chart(_chart1)
    return (chart2,)


@app.cell
def __(chart1, df2):
    matching_values_ids = []
    if not chart1.value.empty:
        for match, check in zip(chart1.value["matches"], chart1.value["match"]):
            if check:
                for m in match:
                    matching_values_ids.append(m)

    _matches = []
    for _mol_id in df2["id"]:
        if _mol_id in matching_values_ids:
            _matches.append(1)
        else:
            _matches.append(0)

    df2_new = df2.assign(match = _matches)
    return check, df2_new, m, match, matching_values_ids


@app.cell
def __(chart1, chart2, mo):
    mo.hstack([chart1, chart2])
    return


if __name__ == "__main__":
    app.run()
