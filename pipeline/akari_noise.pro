pro akari_noise, image_array, edited_image_array

;Purpose:
;   This step uses connected_pixels to find the point sources
;   The mode and variance of the background flux is found using sky_stats
;   This value of the variance if added to the header, called noise
;   And the value of the mode is added to the header, called sky_mode
;   This value of the noise and mode will be used in the coadding step to weight the images
;   And the value of the mode will be used in the coadding step to reduce the contract in the images
;Calling sequence:
;   akari_noise, image_array, edited_image_array
;Inputs:
;   array_image - array of structures, each containing information about an image
;Outputs:
;   edited_image_array - array of structures after it's been through noise step
;Keywords:
;   none
;Author & history:
;   Helen Davidge Feb 2014, OU
;   ed for MIR image, Helen Davidge, Apr 2014, OU

;number of pixels
num_pixels = 1.0

;reading in number of structures
numberofstruc = size(image_array, /n_elements)
;reading in number of strings in header
sizeofheader = size(image_array[0].header, /n_elements)
;size of new header
newsize = sizeofheader + 2
;reading in x & y dimensions of images
array = size(image_array[0].image)
xsize = array(1)
ysize = array(2)

;reading in detector
long_detector = fxpar(image_array[0].header, 'DETECTOR')
;removing zeros in the strings
detector = strcompress(long_detector, /remove_all)
;reading in exposure time
time = fxpar(image_array[0].header, 'EXPTIME')
long_filter = fxpar(image_array[0].header, 'FILTER')
filter = strcompress(long_filter, /remove_all)

;setting the pixel locations of the image, not including the slit mask
if(detector eq 'NIR') then begin
  xmin = 0
  xmax = 411
  ymin = 390
  ymax = 511
endif
if(detector eq 'MIRS') then begin
  xmin = 0
  xmax = 29
  ymin = 0
  ymax = 255
endif
if(detector eq 'MIRL') then begin
  xmin = 237
  xmax = 255
  ymin = 0
  ymax = 204
endif  

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

;now need to combine this photon noise image with the genetic one created using the darks.
;read in noise image created using darks
;this is the noise created by dark current & readout noise
;NOTE this is just for NIR filter, will need to create similar for MIR-S/L filers
if (detector eq 'NIR') then begin
   fits_read, '/Users/helen/Documents/AKARI/noise/made_from_dark/NIR_long_noise.fits', noise_dark
   fits_read, '/Users/helen/Documents/AKARI/dark/idl_images/processed/image/processed_idl_' +detector +'_long.fits', dark_image, dark_header
endif else begin
  if (detector eq 'MIRS') then begin
    fits_read, '/Users/helen/Documents/AKARI/noise/made_from_dark/MIRS_long_noise.fits', noise_dark
    fits_read, '/Users/helen/Documents/AKARI/dark/idl_images/processed/image/processed_idl_' +detector +'_long.fits', dark_image, dark_header
  endif else begin
    if (detector eq 'MIRL') then begin
      fits_read, '/Users/helen/Documents/AKARI/noise/made_from_dark/MIRL_long_noise.fits', noise_dark
      fits_read, '/Users/helen/Documents/AKARI/dark/idl_images/processed/image/processed_idl_' +detector +'_long.fits', dark_image, dark_header
    endif else print, 'Detector not found'
  endelse  
endelse

;setting gain value
if (detector eq 'NIR') then begin
   gain = 6.0
     a = 0
  b = 390
  c = 390
  d = 511
endif
if(detector eq 'MIRS') then begin
   gain = 10.0
  a = 29
  b = 255
  c = 0
  d = 29
endif
if(detector eq 'MIRL') then begin
     gain = 10.0
endif

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
  
  ;new_image = original_image[a:b, c:d]
  ;original_image_no_slit = new_image
  mask = original_mask
  mask[xmin:xmax, ymin:ymax] = 20
  good_pixel = where(mask lt 0.1, complement = bad_pixel)
  new_image = original_image[good_pixel]
  
  
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
  ;
  number = 2.0
 ;value for L15 IRAC validation field;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; number = 5.0
  for count = 0, 21 do begin
;   for count = 0, 3 do begin
  ;while (iteration lt 21) do begin
    ;finding the sd of the image[area]
    sd = stddev(new_image)
    ;finding the mean of the image[area]
    mean = mean(new_image)
    ;max/min values for pixels
    min_value = mean - (number * sd)
    max_value = mean + (number * sd)
    ;getting rid of pixels not within max/min
    bad_pixel_small = where(new_image lt min_value, complement = good_pixel_small)
    new_image = new_image[good_pixel_small]
    bad_pixel_big = where(new_image gt max_value, complement = good_pixel_big)
    new_image = new_image[good_pixel_big]
    ;iteration = iteration + 1
    ;endwhile
    endfor

  ;if(filter eq 'N2') then num = 50.0
  if(filter eq 'N2') then num = 5.0
  ;if(filter eq 'N3') then num = 12.0
  if(filter eq 'N3') then num = 5.0
  ;if(filter eq 'N4') then num = 25.0
  ;for ELIAS north with background 'guess'
  if(filter eq 'N4') then num = 5.0
  ;if(filter eq 'S7') then num = 65.0
  if(filter eq 'S7') then num = 3.5
;  ;for ELAIS north background 'guess'
    if(filter eq 'S9W') then num = 3.5
;  if(filter eq 'S9W') then num = 70.0
  ;if(filter eq 'S11') then num = 170.0
;for IRAC dark field
;  if(filter eq 'S11') then num = 145.0
;  ;for ELAIS north background 'guess'
    if(filter eq 'S11') then num = 3.5
  ;if(filter eq 'L15') then num = 135.0
  ;for ELAIS north with background 'guess'
  ;if(filter eq 'L15') then num = 5.0
  ;for ADFS with background 'guess'
  if(filter eq 'L15') then num = 4.5
  ;if(filter eq 'L18W') then num = 170.0
  ;if(filter eq 'L24') then num = 80.0 
  if(filter eq 'L18W') then num = 4.5
  if(filter eq 'L24') then num = 4.5
  
;code to 'smooth' the image and remove most of the earth light gradient so point sources can be found and masked

;need to mask the slit in original_image

  smoothed_image = median(original_image,20)
  image_minus_background_guess = original_image - smoothed_image

  connected_pixels, image_minus_background_guess, x, y, totalflux, threshold = num * sd, peakflux=peakflux, label_image=sources
  ;connected_pixels, original_image, x, y, totalflux, threshold = , peakflux=peakflux, label_image=sources

  ;need to mask slit_mask pixels.
  if(detector eq 'NIR') then sources[*, c:d] = 1.0
  if(detector eq 'MIRS') then sources[c:d, *] = 1.0
  ;if(filter eq 'S11') then sources[bad_pixel] = 1.0
  sources[bad_pixel] = 1.0

  ;mask all pixels in image, which are gt 0 in mask
  mask_sources = where(sources gt 0, complement = background_flux)

  ;finding the variance of the background flux
  background_pixels = original_image[background_flux]
  
if(detector eq 'NIR') then begin
  mu = mean(background_pixels)
  var = stddev(background_pixels)
endif else begin
  sky_stats, background_pixels, mu, var
endelse

  ;sd = stddev(background_pixels)

  ;Edit headers to add noise
  sxaddpar, original_header, "NOISE", "DONE"
  sxaddpar, original_mask_header, "NOISE", "DONE"
  sxaddpar, original_noise_header, "NOISE", var, "DONE"
  sxaddpar, original_header, "NOISE", var, "DONE"
  
  ;edit headers to add sky_mode
  sxaddpar, original_header, "SKY_MODE", "DONE"
  sxaddpar, original_mask_header, "SKY_MODE", "DONE"
  sxaddpar, original_noise_header, "SKY_MODE", mu, "DONE"
  sxaddpar, original_header, "SKY_MODE", mu, "DONE"  

  ;creating a 2d shot noise image
  noise_image = original_image
  
  ;mask bright sources
  ;noise_image[mask_sources] = 0
  ;mask slit area
  noise_image[xmin:xmax, ymin:ymax] = 0

  ;go through the pixels one at a time
;  for ipix = 0, (xsize - 1) do begin
;    for jpix = 0, (ysize - 1) do begin
      ;calculating number of electrons per pixel
      ;setting all pixels less than 0 to 0
;      if(original_image[ipix, jpix] lt 0.0) then noise_image[ipix, jpix] = 0
      ;number of electrons = ADU * gain
;      num_electrons = noise_image[ipix, jpix] * gain
;      num_electrons_per_sec = num_electrons / time
      ;assuming 1 electron per 1 photon
;      shot_noise = sqrt(num_electrons_per_sec)
;      ;combining shot noise, dark current & read out noise
;      noise_image[ipix, jpix] = sqrt(num_electrons_per_sec + (noise_dark[ipix, jpix] ^ 2.0))     
;    endfor
; endfor

;photons per pixel from background
num_background_electrons = mu * gain
num_background_electrons_per_sec = num_background_electrons / time

;lets stay working in ADUs
  ;go through the pixels one at a time
  for ipix = 0, (xsize - 1) do begin
    for jpix = 0, (ysize - 1) do begin
      ;calculating number of electrons per pixel
      ;setting all pixels less than 0 to 0
      if(original_image[ipix, jpix] lt 0.0) then noise_image[ipix, jpix] = 0
      ;number of electrons = ADU * gain
      num_electrons = noise_image[ipix, jpix] * gain
      num_electrons_per_sec = num_electrons / time
      ;assuming 1 electron per 1 photon
      shot_noise = sqrt(num_electrons_per_sec)
      ;find the value for the combined number of dark current photons and readout photons
      ;setting all pixels in dark_image < 0 to 0
      if(dark_image[ipix, jpix] lt 0.0) then dark_image[ipix, jpix] = 0
      num_dark_electrons = dark_image[ipix, jpix] * gain
      num_dark_electrons_per_sec = num_dark_electrons / time
      noise_image[ipix, jpix] = sqrt(num_electrons_per_sec + (num_pixels * (num_background_electrons_per_sec + num_dark_electrons_per_sec)))
;      noise_image[ipix, jpix] = sqrt(num_electrons_per_sec + (num_pixels * (num_dark_electrons_per_sec)))
;      noise_image[ipix, jpix] = sqrt((num_pixels * (num_background_electrons_per_sec + num_dark_electrons_per_sec)))
;      noise_image[ipix, jpix] = mu + dark_image[ipix, jpix]
    endfor
 endfor



  ;creating the noise image, which is the rms of the pixel flux per second.
  ;going through one pixel at a time, and finding the rms of the flux per second
  ;for ipix = 0, (xsize - 1) do begin
    ;for jpix = 0, (ysize - 1) do begin
     ; pixel = original_image[ipix, jpix]
      ;flux per second
      ;flux_per_second = pixel / exposure
      ;if(flux_per_second lt 0.0) then flux_per_second = 0.0
      ;photon_noise = sqrt(flux_per_second)
      ;we want the square of the photon_noise and the square of the dark_noise, add these together, and then square-root
      ;square of the photon noise
      ;sqr_photon_value = photon_noise ^ 2.0
      ;square of the dark_noise
      ;sqr_dark_value = noise_dark[ipix, jpix] ^ 2.0
      
      ;total_noise = sqrt(sqr_photon_value + sqr_dark_value)   
     ; original_noise[ipix, jpix] = total_noise
    ;endfor
  ;endfor

  ;load edited information into the new structure
  new_image_array[i].image = original_image
  new_image_array[i].header = original_header
  new_image_array[i].mask_image = original_mask
  new_image_array[i].mask_header = original_mask_header
  new_image_array[i].noise = noise_image
  new_image_array[i].noise_header = original_noise_header
  new_image_array[i].history = original_history
endfor

edited_image_array = new_image_array

end