pro cosmic_ray, image_array, edited_image_array

; Purpose
;      Note this only finds cosmic rays in the background, not in the point sources
;      This is to be used with akari_pipeline
;      To detect and flag cosmic rays
;      All pixels flagged as cosmic rays have been set to 2 in mask image
;      a new array is created from image[0:n-2] - image[1-n-1]
;      A pixel will be flagged in this array if the difference > a preset value
;      The pixel location in new array is the same location as in original image
;      fits which have been through cosmic_ray should have 'COSMIC_R' = 'DONE' in header
;      NOTE need to edit this this only the background has point sources removed
;Calling sequence:
;     cosmic_ray, array_image, edited_array_image
;Inputs:
;     array_image - array of structures, each containing information about an image
;Outputs:
;     edited_image_array - array of structures after its been through cosmic ray step
;Keywords:
;     none
;Author & history:
;     Helen Davidge 2013

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
;reading in detector
long_detector = fxpar(image_array[0].header, 'DETECTOR')
;removing zeros in the strings
detector = strcompress(long_detector, /remove_all)
;reading in filter
long_filter = fxpar(image_array[0].header, 'FILTER')
;removing zeros in the strings
filter = strcompress(long_filter, /remove_all)

if(detector eq 'NIR') then begin
  a = 0
  b = 390
  c = 390
  d = 511
endif
if(detector eq 'MIRS') then begin
  a = 29
  b = 255
  c = 0
  d = 29
endif
;this is done after dewraping, so do not need to mask slit in MIRL images
;if(detector eq 'MIRL') then begin
;  a = 0
;  b = 522
;  c = 0
;  d = 0
;endif  

;creating an new template structure for edited images
blank_image = {image:fltarr(xsize,ysize), $
header:strarr(newsize), $
mask_image:bytarr(xsize,ysize), $
mask_header:strarr(newsize), $
noise:fltarr(xsize,ysize), $
noise_header:strarr(newsize), $
history:''}
;creating a array with number of stuructures as there are fits
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
master_image = original_image
;new_image = original_image
;selecting just the background to find cosmic rays, masking point sources

  
  ;selecting the part of the image not the slit
   if(detector eq 'NIR') then begin
      new_image = original_image[*, a:b]
    endif
   if(detector eq 'MIRS') then begin
     new_image = original_image[a:b, *]
   endif
   if(detector eq 'MIRL') then begin
      new_image = original_image
   endif

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
if(detector eq 'MIRS' or detector eq 'MIRL') then begin
  ;if(filter eq 'N3') then num = 12.0
  ;if(filter eq 'N4') then num = 25.0
  ;if(filter eq 'S7') then num = 65.0
  ;if(filter eq 'S11') then num = 145.0
  ;if(filter eq 'L15') then num = 140.0
  ;if(filter eq 'L24') then num = 80.0 
  if(filter eq 'N2') then num = 20.0
  if(filter eq 'N3') then num = 20.0
  if(filter eq 'N4') then num = 20.0
  if(filter eq 'S7') then num = 7.0
  if(filter eq 'S9W') then num = 7.0
  if(filter eq 'S11') then num = 7.0
  if(filter eq 'L15') then num = 4.5
  if(filter eq 'L18W') then num = 4.5
  if(filter eq 'L24') then num = 4.5

;code to 'smooth' the image and remove most of the earth light gradient so point sources can be found and masked
;  smoothed_image = median(original_image,20)
  smoothed_image = median(original_image,20)
  image_minus_background_guess = original_image - smoothed_image
  
  ;find background value to subtract
  ;mask slit
  if(detector eq 'NIR') then image_minus_background_guess[*, c:d] = mean(new_image)
  if(detector eq 'MIRS') then image_minus_background_guess[c:d, *] = mean(new_image)
  
  sky_stats, image_minus_background_guess, mu, var
 
  image_minus_background_guess = image_minus_background_guess - mu

  connected_pixels, image_minus_background_guess, x, y, totalflux, threshold = num * sd, peakflux=peakflux, label_image=sources
  ;connected_pixels, original_image, x, y, totalflux, threshold = , peakflux=peakflux, label_image=sources

  ;need to mask slit_mask pixels.
  ;if(filter eq 'S11') then sources[bad_pixel] = 1.0
  ;sources[c:d, *] = 1.0
  if(detector eq 'NIR') then sources[*, c:d] = 1.0
  if(detector eq 'MIRS') then sources[c:d, *] = 1.0

  ;mask all pixels in image, which are gt 0 in mask
  mask_sources = where(sources gt 0.0, complement = background_flux)

  ;finding the mode, mean & variance of the background flux
  background_pixels = original_image[background_flux]
  ;sky_stats, background_pixels, mu, var
  mean = mean(background_pixels)
  ;masking point sources & slit mask
  sources_to_mask = where(sources gt 0.0)

;  image2 = original_image
;this was = mean, before the background was subtracted from the image
  original_image[sources_to_mask] = 0.0
;  original_image[sources_to_mask] = mean(new_image)
endif

  ;reading in name of file
  name = fxpar(original_header, 'NAME')  
  ;finding the size of the array
  array_size = size(original_image)
  n = array_size[4]
  ;creating the new array to hold image[0:n-2] - image[1-n-1]
  data1 = original_image[0:n-2]
  data2 = original_image[1:n-1]
  new_array = data1 - data2
  ;pixels with a difference > 'difference' will be masked
;if(detector eq 'MIRS' or detector eq 'MIRL') then $
  if(detector eq 'MIRS') then begin
  difference = 3.0 * stddev(new_array)
;  difference = 2.0 * stddev(new_array)
  endif
    if(detector eq 'NIR') then begin
      difference = 7.5 * sd
  endif
  if(detector eq 'MIRL') then begin
  ;below is a good base value to start with
  difference = 10.0 * sd
  endif
;;;;;    else difference = 10.0 * sd
;trying to improve the flux of the galaxies
;  difference = 4.0 * stddev(new_array)

  cosmic_ray = where(new_array gt difference, n_crs)
  ;checking that cosmic_ray does not = -1
  ray_array = size(cosmic_ray)
  bad_pixel = ray_array[2]

  if (bad_pixel eq 1) then begin
    print, 'File ', name, ': no cosmic rays detected'
    ;Editing the head to say it has been through cosmic ray step
    sxaddpar, original_header, "COSMIC_R", "DONE", "image not changed"
    ;edit mask header to say it has been through cosmic ray step
    sxaddpar, original_mask_header, "COSMIC_R", "DONE", "mask not changed'
    ;edit noise header to say it has been through cosmic ray step
    sxaddpar, original_noise_header, "COSMIC_R", "DONE", "mask not changed'
  endif else begin
      ;giving all cosmic ray pixels the value 2 in mask_image
      original_mask[cosmic_ray] = 2
      ;note I have not checked that x[n-1] is not a cosmic ray
      print, 'File ', name, " has been through cosmic ray step"
      ;Editing the head to say it has been through cosmic ray step
      sxaddpar, original_header, "COSMIC_R", "DONE", "image not changed, see mask image"
      ;editing mask header to say it has been through cosmic ray step
      sxaddpar, original_mask_header, "COSMIC_R", "DONE", "flagged pixel = 2"
      ;edit noise header to say it has been through cosmic ray step
      sxaddpar, original_noise_header, "COSMIC_R", "DONE"
    endelse

  ;load edited information into the new structure
  new_image_array[i].image = master_image
  new_image_array[i].header = original_header
  new_image_array[i].mask_image = original_mask
  new_image_array[i].mask_header = original_mask_header
  new_image_array[i].noise = original_noise
  new_image_array[i].noise_header = original_noise_header
  new_image_array[i].history = original_history
endfor

edited_image_array = new_image_array

end