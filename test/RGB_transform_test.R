data_true = read.csv2("RGB_transform_test.csv", dec = ".")

RGB_transform = Vectorize(RGB_transform) 

data_check = RGB_transform(data_true$R, data_true$G, data_true$B, norm_val = 1)
data_check = data.frame(t(data_check)) # transpose matrix

isTRUE(all.equal(data_true[c(4:13)], data_check, tolerance = 0.002))
