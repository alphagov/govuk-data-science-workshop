# A script of boring data wrangling, to keep it out of the way of the workshop.
#
# References:
# https://plotly.com/python/v3/igraph-networkx-comparison/

# Load packages
import os
import pandas as pd
from igraph import Graph, VertexSeq
from igraph.drawing.colors import ClusterColoringPalette, color_to_html_format
from plotly.graph_objs import Figure, Scatter, Layout, layout
import plotly.offline as pyo

# Set notebook mode to work in offline
pyo.init_notebook_mode()

# Read the name of the edgelist dataset file from an environment variable.
DIR_DATA_RAW = os.getenv("DIR_DATA_RAW")

# Load the edgelist dataset into a pandas data frame
edges = pd.read_csv(
    DIR_DATA_RAW + "/structural_network_adjacency_list_20190301.csv",
    usecols=["source_base_path", "sink_base_path"],
)
edges.drop_duplicates(inplace=True)

# Filter for pages whose URLs contain the word 'childcare'
search_string = "childcare"
childcare_edges = edges[
    (edges.source_base_path.str.contains(search_string))
    | (edges.sink_base_path.str.contains(search_string))
]

# Construct a graph object from the edges
g = Graph.DataFrame(childcare_edges, directed=True)

# The graph has one big component, and many small ones
# that are disconnected from the big one.
# Keep only the largest component.
components = g.clusters(mode="weak")
G = components.giant()

# Detect communities within the graph.  The spinglass
# algorithm allows for a maximum number of communities
# to be set.  It might detect fewer than this, but it
# won't detect more.  Every node (every page) will be
# assigned to exactly one community.
communities = G.community_spinglass(spins=5)

# Calculate the degree of each node (each page).  The
# degree is the number of edges into and out of the
# node.
degrees = [v.degree(mode="out") for v in VertexSeq(G)]

# Extract bits for the viz
labels = list(G.vs["name"])
N = len(labels)
E = [e.tuple for e in G.es]  # list of edges

# Prepare the layout in igraph
# layt=G.layout('kk') # kamada-kawai layout
layt = G.layout("fr")  # fruchterman-reingold

# Detect communities within the graph.  The spinglass
# algorithm allows for a maximum number of communities
# to be set.  It might detect fewer than this, but it
# won't detect more.  Every node (every page) will be
# assigned to exactly one community.
communities = G.community_spinglass(spins=5)
pal = ClusterColoringPalette(len(communities))
G.vs["color"] = pal.get_many(communities.membership)
colours = list(G.vs["color"])
colours

hexes = [color_to_html_format(rgba)[:7] for rgba in colours]
hexes

# Prepare the layout in igraph
# layt=G.layout('kk') # kamada-kawai layout
layt = G.layout("fr")  # fruchterman-reingold


Xn = [layt[k][0] for k in range(N)]
Yn = [layt[k][1] for k in range(N)]
Xe = []
Ye = []

for e in E:
    Xe += [layt[e[0]][0], layt[e[1]][0], None]
    Ye += [layt[e[0]][1], layt[e[1]][1], None]

# Plot the edges
trace1 = Scatter(
    x=Xe,
    y=Ye,
    mode="lines",
    line=dict(color="rgb(210,210,210)", width=1),
    hoverinfo="none",
)

# Plot the nodes
trace2 = Scatter(
    x=Xn,
    y=Yn,
    mode="markers",
    name="ntw",
    marker=dict(
        symbol="circle",
        size=10,
        color=hexes,
        line=dict(color="rgb(50,50,50)", width=0.5),
    ),
    text=labels,
    hoverinfo="text",
)

# Hide the axes
axis = dict(
    showline=False,  # hide axis line, grid, ticklabels and  title
    zeroline=False,
    showgrid=False,
    showticklabels=False,
    title="",
)

# Set the size of the visualisation
width = 800
height = 800

# Construct the overall graph
layout = Layout(
    title="",
    font=dict(size=12),
    showlegend=False,
    autosize=False,
    width=width,
    height=height,
    xaxis=layout.XAxis(axis),
    yaxis=layout.YAxis(axis),
    margin=layout.Margin(
        l=40,
        r=40,
        b=85,
        t=100,
    ),
    hovermode="closest",
    annotations=[
        dict(
            showarrow=False,
            text="",
            xref="paper",
            yref="paper",
            x=0,
            y=-0.1,
            xanchor="left",
            yanchor="bottom",
            font=dict(size=14),
        )
    ],
)

# Combine the traces
data = [trace1, trace2]

# Construct the final graph
fig = Figure(data=data, layout=layout)
