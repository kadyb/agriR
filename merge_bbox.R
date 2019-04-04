merge_bbox = function(vlayer1, vlayer2) {
  library("units")
  
  if((st_crs(vlayer1) == st_crs(vlayer2)) == FALSE) stop("Different CRS")
  
  bbox1 = st_bbox(vlayer1)
  bbox2 = st_bbox(vlayer2)
  
  # this ignores that the field has several parts
  c1 = st_centroid(st_as_sfc(bbox1))
  c2 = st_centroid(st_as_sfc(bbox2))
  dist = st_distance(c1, c2)
  units(dist) = "km"
  if(dist > set_units(20, km)) stop("Too long distance between fields")
  
  # output as copied object
  bbox_out = bbox1
  
  # compare xmin
  if(bbox1[1] > bbox2[1]) bbox_out[1] = bbox2[1]
  # compare ymin
  if(bbox1[2] > bbox2[2]) bbox_out[2] = bbox2[2]
  # compare xmax
  if(bbox1[3] < bbox2[3]) bbox_out[3] = bbox2[3]
  # compare ymax
  if(bbox1[4] < bbox2[4]) bbox_out[4] = bbox2[4]
  
  return(st_as_sfc(bbox_out))
  
}

# Info:
### Merge bounding boxes of two vector layers. The layer can contain several objects.
# Input:
### vlayer1 - first sf layer
### vlayer2 - second sf layer

# Example:
#vlayer1 = st_read("path_to_polygon1")
#vlayer2 = st_read("path_to_polygon2")
#merged_bbox = merge_bbox(vlayer1, vlayer2)