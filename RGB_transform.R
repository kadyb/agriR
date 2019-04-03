RGB_transform <- function(R, G, B, norm_val) {
   # Implementation from: 
   # https://en.wikipedia.org/wiki/HSL_and_HSV#Formal_derivation
  
  if(R > norm_val | G > norm_val | B > norm_val)
     warning("Normalization value is smaller than input value.", immediate. = TRUE)
   
  # Normalize
  R = R/norm_val
  G = G/norm_val
  B = B/norm_val
   
  M = max(R, G, B)
  m = min(R, G, B)
  C_1 = M - m
  
  if(C_1 == 0) {
    H_1 = NA
  } else if(M == R) {
    H_1 = ((G - B)/C_1) %% 6
  } else if(M == G) {
    H_1 = ((B - R)/C_1) + 2
  } else if(M == B) {
    H_1 = ((R - G)/C_1) + 4
  }
  
  H_1 = 60 * H_1
  
  alpha = (2*R - G - B)/2
  
  beta = (sqrt(3)/2)*(G - B)
  
  # Converse radians to deegres and transform from negative values
  H_2 = ((atan2(beta, alpha) * 180 / pi) + 360) %% 360
  
  C_2 = sqrt(alpha^2 + beta^2)
  
  H_2 = ifelse(C_2 == 0, NA, H_2)
  
  V = M
  
  L = (M + m)/2
  
  I = (R + G + B)/3
  
  S_HSV = ifelse(V == 0, 0, C_1/V)
  
  S_HSL = ifelse(L == 0 | L == 1, 0, C_1/(1-abs(2*L-1)))
  
  S_HSI = ifelse(I == 0, 0, 1-(m/I))

  return(c("Hue_1" = H_1,
           "Hue_2" = H_2,
           "Chroma_1" = C_1,
           "Chroma_2" = C_2,
           "Value" = V,
           "Lightness" = L,
           "Intensity" = I,
           "Saturation_HSV" = S_HSV,
           "Saturation_HSL" = S_HSL,
           "Saturation_HSI" = S_HSI))
}

# Info:
### Transform RGB to HSV, HSI and HSL color space
# Input:
### R - Red channel
### G - Green channel
### B - Blue channel
### norm_val - Divider to normalize input values (they can not exceed 1 after dividing)

# Example:
#RGB_transform = Vectorize(RGB_transform)
#sample_data = data.frame(R = c(runif(10, 0, 255)), 
#                         G = c(runif(10, 0, 255)),
#                         B = c(runif(10, 0, 255)))
#data_transformed = RGB_transform(sample_data$R, sample_data$G, sample_data$B, 255)
#data_transformed = data.frame(t(data_transformed)) # transpose matrix
