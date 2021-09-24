library(tidyverse)
library(tidygraph)
library(ggraph)
library(igraph)
library(tidytext)

# Load the graph
g <-
  read_csv("./data/raw/structural_network_adjacency_list_20190301.csv") %>%
  as_tbl_graph() %>%
  activate(nodes) %>%
  mutate(base_name = str_remove(name, "[\\?#].*$")) %>%
  mutate(base_name = str_remove(base_name, "^.*\\/"))

# How many of each type of edge?
g %>%
  activate(edges) %>%
  as_tibble() %>%
  count(link_type)

g %>%
  activate(nodes) %>%
  filter(node_is_universal())

# How many compenents (disconnected subgraphs)?  And what size?
components <-
  g %>%
  activate(nodes) %>%
  mutate(group = group_components(type = "weak"))

# A very large group, and many smaller groups
components %>%
  as_tibble() %>%
  count(group, sort = TRUE)

# The home page is at the center of the largest group
components %>%
  activate("nodes") %>%
  mutate(is_centre = node_is_center()) %>%
  filter(name == "/")

# How distant are pages in the homepage group from the homepage?
home_distance <-
  components %>%
  activate("nodes") %>%
  filter(group == 1) %>%
  mutate(dist_to_home = node_distance_to(name == "/")) %>%
  mutate(dist_from_home = node_distance_from(name == "/")) %>%
  as_tibble

home_distance %>%
  count(dist_to_home) %>%
  ggplot(aes(dist_to_home, n)) +
  geom_point() +
  scale_y_log10()

# The page furthest from home but still connected is
# /government/news/rail-franchising
home_distance %>%
  filter(!is.infinite(dist_to_home)) %>%
  filter(dist_to_home == max(dist_to_home))

# What is a shortest path from /government/news/rail-franchising to home?
components %>%
  shortest_paths("/government/news/rail-franchising", "/") %>%
  pluck("vpath", 1) %>%
  unclass()

# Distances from home (the other way)
# No pages are linked to from home (apparently)
home_distance %>%
  count(dist_from_home)

# A component with only one page
components %>%
  filter(group == 9474)

# Components with exactly 10 pages
components %>%
  as_tibble() %>%
  count(group) %>%
  filter(n == 10) %>%
  filter(group %in% c(402, 403)) %>%
  as_tibble()

components %>%
  filter(group %in% c(402:411)) %>%
  ggraph(layout = "igraph", algorithm = "kk") +
  geom_edge_link() +
  geom_node_point()

# Is the home page the most central (by degree)?  No.
g %>%
  activate(nodes) %>%
  mutate(centrality = centrality_degree()) %>%
  mutate(group = group_components(type = "weak")) %>%
  as_tibble() %>%
  slice_max(centrality, n = 10) %>%
  select(name, centrality)

# TODO: compare several community detection algorithms group_*

# Are URLs that mention "brexit" a suitable subset?
brexit <-
  g %>%
  activate("nodes") %>%
  morph(to_subgraph, str_detect(name, "brexit")) %>%
  crystallise() %>%
  pluck("graph", 1)

# There are several disconnected subgraphs
brexit %>%
  ggraph() +
  geom_edge_link() +
  geom_node_point()

brexit_main <-
  brexit %>%
  mutate(group = group_components(type = "weak")) %>%
  group_by(group) %>%
  mutate(group_size = n()) %>%
  ungroup() %>%
  filter(group_size == max(group_size))

brexit_main %>%
  # mutate(group = group_walktrap()) %>% # 146
  mutate(group = group_spinglass()) %>% # 14 but can limit with spins=
  # mutate(group = group_optimal()) %>% # slow
  # mutate(group = group_leading_eigen()) %>% # 18
  # mutate(group = group_label_prop()) %>% # 27
  # mutate(group = group_infomap()) %>% # 38
  # mutate(group = group_edge_betweenness()) %>% # 22
  ggraph() +
  geom_edge_link() +
  geom_node_point(aes(colour = factor(group)), size = 10)

# Choose one term from each URL by its tf.idf score
tf_idf <-
  brexit_main %>%
  activate("nodes") %>%
  as_tibble() %>%
  mutate(term = str_split(base_name, "[^a-z0-9]")) %>%
  select(.tidygraph_node_index, term) %>%
  unnest(term) %>%
  count(.tidygraph_node_index, term) %>%
  bind_tf_idf(term, .tidygraph_node_index, n) %>%
  group_by(.tidygraph_node_index) %>%
  slice_max(tf_idf, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(.tidygraph_node_index, term)

# Compute node importance
  brexit_main %>%
  activate("nodes") %>%

brexit_plot <-
  brexit_main %>%
  activate("nodes") %>%
  left_join(tf_idf, by = ".tidygraph_node_index") %>%
  mutate(group = group_spinglass(spins = 5)) %>%
  mutate(centrality = centrality_degree()) %>%
  group_by(group) %>%
  mutate(is_central = centrality == max(centrality)) %>%
  ungroup()

brexit_plot %>% # 14
  as_tibble() %>%
  select(group, centrality, is_central, base_name) %>%
  arrange(group, desc(centrality), base_name) %>%
  group_split(group)

brexit_plot %>%
  ggraph(layout = "nicely") +          # fr and kk are okay too
  geom_edge_link() +
  geom_node_point(aes(colour = as.character(group),
                      alpha = as.integer(is_central)),
                  size = 10) +
  geom_node_text(aes(label = centrality)) +
  scale_alpha(range = c(0.2, 1)) +
  theme_graph() +
  nowt()
