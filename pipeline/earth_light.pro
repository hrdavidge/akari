pro earth_light, image_array, edited_image_array


; Purpose
;      This is to be used with akari_pipeline
;      This step removes the earth light from the MIRL and MIRS filters
;Calling sequence:
;     earth_light, image_array, edited_image_array
;Inputs:
;     array_image - array of structures, each containing information about an image
;Outputs:
;     edited_image_array - array of structures after its been through earth_light step
;Keywords:
;     none
;Author & history:
;     Helen Davidge, OU May 2014
;     ed Helen Davidge, OU July 2014 - to correct the edge problem

;reading in number of structures
numberofstruc = size(image_array, /n_elements)
;reading in number of strings in header
sizeofheader = size(image_array[0].header, /n_elements)
;size of new header
newsize = sizeofheader + 1
;reading in x & y dimensions of images
array = size(image_array[0].image)
xsize = array(1)
ysize = array(2)

;reading in filter
long_filter = fxpar(image_array[0].header, 'FILTER')
;removing zeros in the strings
filter = strcompress(long_filter, /remove_all)
;reading in detector
long_detector = fxpar(image_array[0].header, 'DETECTOR')
;removing zeros in the strings
detector = strcompress(long_detector, /remove_all)

;if(filter eq 'L15') then num = 10.0
;if(filter eq 'S7') then num = 10.0
;if(filter eq 'L24') then num = 10.0
;if(filter eq 'L18W') then num = 10.0

;if detector = NIR, do not need to do this step
if(detector eq 'NIR') then begin
  edited_image_array = image_array
endif else begin
;creating a new template structure for edited images
blank_image = {image:fltarr(xsize,ysize), $
header:strarr(newsize), $
mask_image:bytarr(xsize,ysize), $
mask_header:strarr(newsize), $
noise:fltarr(xsize,ysize), $
noise_header:strarr(newsize), $
history:''}
;creating an array with number of stuructures as there are fits
new_image_array = replicate(blank_image, numberofstruc)

;going through each structure one at a time
for i = 0, (numberofstruc - 1) do begin
  ;reading in all of the info in the structure
  original_image = image_array[i].image
  original_header = image_array[i].header
  original_mask = image_array[i].mask_image
  original_mask_header = image_array[i].mask_header
  original_noise = image_array[i].noise
  original_noise_header = image_array[i].noise_header
  original_history = image_array[i].history
 
  ;reading in name of file
  name = fxpar(original_header, 'NAME')
;stephen's code
  ;creating a polyinomal fit of the image
;  result = sfit(original_image, 6)

;  image2 = original_image

  ;finding the point sources
;  bad = where(abs(image2 - result) gt num, nbad)

;  if(nbad gt 0) then image2[bad] = result[bad]

  ;creating a polynomial fit of the image with point sources removed
;  result = sfit(image2, 6)
  ;subtracting the polynimal fit of the image, then adding on the median value of the polynomial
  ;new_image = original_image - (result/20) + median(result/20)
;  new_image = original_image - result + median(result)

;stephen's code edited
  ;setting the pixel locations of the image, not including the slit mask
if(detector eq 'MIRS') then begin
  a = 29
  b = 255
  c = 0
  d = 29
endif
;this is done after dewarping, so do not need to mask slit in MIRL images
if(detector eq 'MIRL') then begin
;  a = 0
  b = 255
;  c = 0
;  d = 0
endif  
  
  ;selecting the part of the image not the slit
   if(detector eq 'MIRS') then begin
     new_image = original_image[a:b, *]
   endif else begin
      new_image = original_image
   endelse
  
  ;setting the values to use with connected_pixels
  ;need to sigma clip this sd, or something, as not all point sources are masked in images containing saturated pixels
  ;sigma clipping the sd of the image
  ;setting inital sigma
  original_initial_sigma = stddev(new_image)
  ;removing pixels which have flux less than lower, and greater than upper
  lower = -1000.0
  upper = 10000.0
  bad_pixel_lower = where(new_image lt lower, complement = good_pixel_lower)
  ;darkshift = mean(dark_image_area[good_pixel_lower])
  new_image = new_image[good_pixel_lower] 
  bad_pixel_upper = where(new_image gt upper, complement = good_pixel_upper)
  ;darkshift = mean(dark_image_area[good_pixel_upper])
  new_image= new_image[good_pixel_upper]
  ;sigma clipping, aka leaving out pixels which are 2sigma away from the mean
  ;iteration = 20
  ;set initial value
  ;iteration = 0

  for count = 0, 21 do begin
  ;value for L15 IRAC validation field;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   for count = 0, 3 do begin
  ;while (iteration lt 21) do begin
    ;finding the sd of the image[area]
    sd = stddev(new_image)
    ;finding the mean of the image[area]
    mean = mean(new_image)
    ;max/min values for pixels
    min_value = mean - (2.0 * sd)
    max_value = mean + (2.0 * sd)
    ;getting rid of pixels not within max/min
    bad_pixel_small = where(new_image lt min_value, complement = good_pixel_small)
    new_image = new_image[good_pixel_small]
    bad_pixel_big = where(new_image gt max_value, complement = good_pixel_big)
    new_image = new_image[good_pixel_big]
    ;iteration = iteration + 1
    ;endwhile
    endfor

;for ADFS
  if(filter eq 'S7') then num = 3.5
;doesn't work for ELAIS north
;  if(filter eq 'S7') then num = 45.0
;for ADFS
;  ;for ELAIS north background 'guess'
    if(filter eq 'S9W') then num = 3.5
;  if(filter eq 'S11') then num = 165.0
;for ELAIS north  
;  if(filter eq 'S11') then num = 90.0
;for IRAC dark field
;  if(filter eq 'S11') then num = 145.0
;  ;for ELAIS north background 'guess'
    if(filter eq 'S11') then num = 3.5
  ;if(filter eq 'L15') then num = 138.0 
  ;for IRAC dark field 
  ;if(filter eq 'L15') then num = 140.0
  ;for ELAIS north
  ;if(filter eq 'L15') then num = 90.0
  ;for ELAIS north with background 'guess'
  ;if(filter eq 'L15') then num = 5.0
  ;for ADFS with background 'guess'
  if(filter eq 'L15') then num = 4.5
  ;if(filter eq 'L18W') then num = 100.0
  ;for IRAC dark field
  if(filter eq 'L18W') then num = 4.5
  if(filter eq 'L24') then num = 4.5 

;code to 'smooth' the image and remove most of the earth light gradient so point sources can be found and masked
  smoothed_image = median(original_image,20)
  image_minus_background_guess = original_image - smoothed_image

  connected_pixels, image_minus_background_guess, x, y, totalflux, threshold = num * sd, peakflux=peakflux, label_image=sources
  ;connected_pixels, original_image, x, y, totalflux, threshold = , peakflux=peakflux, label_image=sources
 
  ;need to mask slit_mask pixels.
  ;if(filter eq 'S11') then sources[bad_pixel] = 1.0
  ;sources[c:d, *] = 1.0
  if(detector eq 'MIRS') then sources[c:d, *] = 1.0

  ;mask all pixels in image, which are gt 0 in mask
  mask_sources = where(sources gt 0.0, complement = background_flux)
 
  ;finding the mode, mean & variance of the background flux
  background_pixels = original_image[background_flux]
  ;sky_stats, background_pixels, mu, var
  mean = mean(background_pixels)
  ;masking point sources & slit mask
  sources_to_mask = where(sources gt 0.0)

  image2 = original_image
  image2[sources_to_mask] = mean

  ;creating a polynomial fit of the image with point sources removed
  ;forADFS S7
  ;result = sfit(image2, 4)
  ;for ELIAS north S7 & L15 ADFS
;  result = sfit(image2, 3)

;if this number goes any smaller, the flux of the point sources are reduced
edge_num = 21

;trying to fix the edge problem
;code for elais north S11
;;;;image2[252:255, 150:255] = mean

;image2[0:4, *] = mean
;image2[252:255, *] = mean
image2[254:255, *] = mean
image2[*, 0:4] = mean
;image2[*, 252:255] = mean

;sorting out missing pixels - this code seems to work :)
;missing_pixels = where(image2 eq 0.0)
;image2[missing_pixels] = mean

  ;Simon's suggestion
  ;This code works, but has slight edge problems
  result = smooth(image2, edge_num, /EDGE_TRUNCATE)
;  stephen's code for sorting out the edge problems
;  result = masked_median_smooth(image2, edge_num, nnearest=8)
  ;everything else, so far....
;  result = smooth(image2, edge_num, /EDGE_TRUNCATE)

  ;subtracting the polynimal fit of the image, then adding on the median value of the polynomial
  ;new_image = original_image - (result/20) + median(result/20)
  new_image = original_image - result + median(result)

;;;below is the formula to mask all pixels within edge_num of the edge
;;;and give the mean value of its 8 nearest neighbours
;;; this doesn't work  
;  ;creating an array to hold the locations of pixels within edge_num of the edge
;  new_mask = original_mask
;  new_mask[*, 0:edge_num] = 20
;  new_mask[*, (b - edge_num):b] = 20
;  new_mask[0:edge_num, *] = 20
;  new_mask[(b - edge_num):b, *] = 20
;  bad_pixel = where(new_mask gt 19.0)
;  num_bad_pixel = size(bad_pixel, /n_elements)
  
;    ;setting max value of x and max value of y
;  x = xsize
;  y = ysize
  
;    for count = 0, (num_bad_pixel - 1) do begin
;    bad_pixel_count = bad_pixel[count]
;    num_rows = bad_pixel_count / x
;    num_columns = bad_pixel_count - (num_rows * x)
;    x_value = num_columns
;    y_value = num_rows

;    if(y_value lt 1) then begin
;      if(x_value gt 0) then begin
;        If(x_value lt (x - 1)) then begin
;            locationsofpixels = [bad_pixel_count + (x - 1), bad_pixel_count + x, $
;            bad_pixel_count + (x + 1), bad_pixel_count + 1, bad_pixel_count - 1]
;            newarray = original_image[locationsofpixels]
;            average = mean(newarray)
;        endif
;      endif
 ;   endif

;     if(y_value lt 1) then begin
;      if(x_value gt (x -2)) then begin
;        average = original_image[x_value, y_value]
;        endif
;      endif
      
;    if(y_value gt (y - 1)) then begin
;      if(x_value gt 0) then begin
;        if(x_value lt (x -1)) then begin
;           ;creating array to hold locations of all neighbouring pixels
;           locationsofpixels = [bad_pixel_count + 1, bad_pixel_count - (x - 1), bad_pixel_count - x, $
;            bad_pixel_count - (x + 1), bad_pixel_count - 1]
;            newarray = original_image[locationsofpixels]
;            average = mean(newarray)
;        endif
;      endif   
;    endif
    
;    ;setting max and min values allowed for x and y
;    if(x_value lt 1) then begin
;      if(y_value lt 1) then begin

;           ;creating array to hold locations of all neighbouring pixels
;           locationsofpixels = [bad_pixel_count + x, bad_pixel_count + (x + 1), bad_pixel_count + 1]
;            newarray = original_image[locationsofpixels]
;            average = mean(newarray)
;      endif else begin
;           if(y_value gt (y - 1)) then begin
;             ;creating array to hold locations of all neighbouring pixels
;             locationsofpixels = [bad_pixel_count + 1, bad_pixel_count - (x - 1), bad_pixel_count - x]
;            newarray = original_image[locationsofpixels]
;            average = mean(newarray)
;           endif else begin
;                ;creating array to hold locations of all neighbouring pixels
;                locationsofpixels = [bad_pixel_count + x, bad_pixel_count + (x + 1), $
;                bad_pixel_count + 1, bad_pixel_count - (x - 1), bad_pixel_count - x]
;            newarray = original_image[locationsofpixels]
;            average = mean(newarray)
;              endelse
;           endelse
;    endif
    
;    if(x_value gt (x - 1)) then begin
;      if(y_value lt 1) then begin
;        ;creating array to hold locations of all neighbouring pixels
;        locationsofpixels = [bad_pixel_count + (x - 1), bad_pixel_count + x, bad_pixel_count - 1]
;            newarray = original_image[locationsofpixels]
;            average = mean(newarray)
;      endif else begin
;           if(y_value gt (y - 1)) then begin
;             ;creating array to hold locations of all neighbouring pixels
;             locationsofpixels = [ bad_pixel_count - x, bad_pixel_count - (x + 1), bad_pixel_count - 1]
;            newarray = original_image[locationsofpixels]
;            average = mean(newarray)
;           endif else begin
;               ;creating array to hold locations of all neighbouring pixels
;               locationsofpixels = [bad_pixel_count + (x - 1), bad_pixel_count + x,$
;               bad_pixel_count - x, bad_pixel_count - (x + 1), bad_pixel_count - 1]
;            newarray = original_image[locationsofpixels]
;            average = mean(newarray)
;              endelse
;         endelse
;  endif
  
;  if(y_value gt 0) then begin
;    if(y_value lt (y - 1)) then begin
;      if(x_value gt 0) then begin
;        if(x_value lt (x - 1)) then begin
;           ;creating array to hold locations of all neighbouring pixels
;           locationsofpixels = [bad_pixel_count + (x - 1), bad_pixel_count + x, bad_pixel_count + (x + 1), $
;           bad_pixel_count + 1, bad_pixel_count - (x - 1), bad_pixel_count - x, $
;           bad_pixel_count - (x + 1), bad_pixel_count - 1]
;            newarray = original_image[locationsofpixels]
;            average = mean(newarray)
;        endif
;      endif
;    endif
;  endif  
;    original_image[num_columns, num_rows] = average
;endfor

;new_image = original_image - result + median(result)

;giving the pixels within edge_num pixels of the edge, the value which they had before
;  new_image[*, 0:edge_num] = original_image[*, 0:edge_num]
;  new_image[*, (b - edge_num):b] = original_image[*, (b - edge_num):b]
;  new_image[0:edge_num, *] = original_image[0:edge_num, *]
;  new_image[(b - edge_num):b, *] = original_image[(b - edge_num):b, *]

;creating an image to find hot pixels
;  new_image[*, 0:10] = original_image[*, 0:10]
;  new_image[*, (b - edge_num):b] = original_image[*, (b - edge_num):b]
;  new_image[0:10, *] = original_image[0:10, *]
;  new_image[(b - edge_num):b, *] = original_image[(b - edge_num):b, *]

;generic edge sorting out
;  new_image[*, 0:edge_num/2.0] = original_image[*, 0:edge_num/2.0]
;  new_image[*, (b - edge_num/2.0):b] = original_image[*, (b - edge_num/2.0):b]
;  new_image[0:edge_num/2.0, *] = original_image[0:edge_num/2.0, *]
;  new_image[(b - edge_num/2.0):b, *] = original_image[(b - edge_num/2.0):b, *]

;for S11 IRAC Dark Field images, 3030001_001
;  new_image[*, 0:15] = original_image[*, 0:15]
;  new_image[*, (b - edge_num/2.0):b] = original_image[*, (b - edge_num/2.0):b]
;  new_image[0:edge_num/2.0, *] = original_image[0:edge_num/2.0, *]
;  new_image[(b - 17):b, *] = original_image[(b - 17):b, *]

;for L15 IRAC validation field phase 1- LHS is fine, top could be improved, bottom & RHS need improving
;   new_image[(b - 10):b, *] = original_image[(b - 10):b, *]

;for L15 IRAC validation field phase 2 - No editing edges

;No masking for L15 Elais north 

;no masking for S11 Elais north
;

;to use for creating images for jakub
;masking the slit area
;new_image = original_image
;new_image[c:d, *] = mean
;masking bad pixels
;need to dewarp mask - this is for L15
;    x00 = 1.9941391944885253906250000000000000000000000000000000000
;    x10 = 0.0430689752101898193359375000000000000000000000000000000
;    x20 = -0.0001911112049128860235214233398437500000000000000000000
;    x01 = 0.9295096993446350097656250000000000000000000000000000000
;    x11 = -0.0003490250674076378345489501953125000000000000000000000
;    x21 = 0.0000026001193873526062816381454467773437500000000000000
;    x02 = 0.0000630844879196956753730773925781250000000000000000000
;    x12 = -0.0000002520212092349538579583168029785156250000000000000
;    x22 = -0.0000000053931654697692010813625529408454895019531250000
;    y00 = 2.4759299755096435546875000000000000000000000000000000000
;    y10 = 0.9619577527046203613281250000000000000000000000000000000
;    y20 = 0.0001764251792337745428085327148437500000000000000000000
;    y01 = -0.0429230332374572753906250000000000000000000000000000000
;    y11 = 0.0008485961006954312324523925781250000000000000000000000
;    y21 = -0.0000028801457574445521458983421325683593750000000000000
;    y02 = 0.0001138863954111002385616302490234375000000000000000000
;    y12 = -0.0000027833827971335267648100852966308593750000000000000
;    y22 =  0.0000000095948253786559689615387469530105590820312500000
    
    ;create the x and y coefficents.
;x_coeff = dblarr(3, 3)
;y_coeff = dblarr(3, 3)
    
;    x_coeff[0, 0] = x00
;x_coeff[1, 0] = x10
;x_coeff[2, 0] = x20
;x_coeff[0, 1] = x01
;x_coeff[1, 1] = x11
;x_coeff[2, 1] = x21
;x_coeff[0, 2] = x02
;x_coeff[1, 2] = x12
;x_coeff[2, 2] = x22

;y_coeff[0, 0] = y00
;y_coeff[1, 0] = y10
;y_coeff[2, 0] = y20
;y_coeff[0, 1] = y01
;y_coeff[1, 1] = y11
;y_coeff[2, 1] = y21
;y_coeff[0, 2] = y02
;y_coeff[1, 2] = y12
;y_coeff[2, 2] = y22

;  new_mask = poly_2d(original_mask, x_coeff, y_coeff)

;  bad_pixels = where(new_mask gt 0.1)
;  new_image[bad_pixels] = mean

  ;Editing the head to say it has been through flat step
  sxaddpar, original_header, "EARTH", "DONE"
  sxaddpar, original_mask_header, "EARTH", "DONE"
  sxaddpar, original_noise_header, "EARTH", "DONE"
    
  ;message to say step has been done on specific image
  print, 'File ', name, " has been through earth light step"
  ;load edited information into the new structure
  new_image_array[i].image = new_image
  new_image_array[i].header = original_header
  new_image_array[i].mask_image = original_mask
  new_image_array[i].mask_header = original_mask_header
  new_image_array[i].noise = original_noise
  new_image_array[i].noise_header = original_noise_header
  new_image_array[i].history = original_history
endfor

edited_image_array = new_image_array
endelse
end