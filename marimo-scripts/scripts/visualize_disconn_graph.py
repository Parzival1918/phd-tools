import marimo

__generated_with = "0.9.4"
app = marimo.App(width="medium")


@app.cell
def __():
    import marimo as mo
    import pickle
    from io import BytesIO
    import networkx as nx
    return BytesIO, mo, nx, pickle


@app.cell
def __(mo):
    pickle_file = mo.ui.file(filetypes=[".pickle"], multiple=False, kind="area", label="Open the disconnectivity graph pickle.")
    pickle_file
    return (pickle_file,)


@app.cell
def __(BytesIO, pickle, pickle_file):
    def read_pickle_graph(file):
        _unpickled = pickle.load(file)
        return _unpickled

    with BytesIO(pickle_file.contents()) as file:
        unpickled = read_pickle_graph(file)

    unpickled
    return file, read_pickle_graph, unpickled


if __name__ == "__main__":
    app.run()
