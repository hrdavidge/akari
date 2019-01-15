pro dark, image_array, edited_image_array

; Purpose
;      This is to be used with akari_pipeline
;      To replicate the dark light step done in the irc pipeline.
;      Note I need to find out if the dark is time dependent, if so
;      this program will need editing.
;      Note I have rememoved the zeros in the string for aot
;      & detector read in from header.
;      This is using super dark & comparing with IRAF pipeline image
;      The discrepancy between the IRAF & IDL step is the mode
;      IRAF uses a parabolic interpolation. I am using sky stats
;      Note wondering if I need do so many iterations.
;      I have already put the dark lab images through linearity & normalisation step $
;      they are stored in: /Users/helen/Douments/AKARI/idl_images/dark
;      fits which have been through dark should have 'DARK' = 'DONE' in header
;      NOTE this step does not equal IRAF step
;Calling sequence:
;     dark, image_array, edited_image_array
;Inputs:
;     array_image - array of structures, each containing information about an image
;Outputs:
;     edited_image_array - array of structures after it's been through dark step
;Keywords:
;     none
;Author & history:
;     Helen Davidge 2013

;constants to use with mask image
;These values are the mode of the dark slit of each detector + exposure length found using dark_slit.pro
NIR_short = 0.0000000000
;NIR_long = 2.2366552352905273437500
NIR_long = 0.1848707646131515502929687500
MIRS_short = -2.24465513229370117187500
;MIRS_long = 9.37239456176757812500
MIRS_long = 0.8365794420242309570312500
MIRL_short = 10.1450338363647460937500
;MIRL_long = 10.2316961288452148437500
MIRL_long = 0.7920699950169192149473929021041840314865112304687500

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
  
  ;reading in AOT - keep this in the for loop for the time being
  long_aot = fxpar(original_header, 'AOT')
  ;reading in exposure length - keep this in for loop for the time being
  expid = fxpar(original_header, 'EXPID')
  
  ;reading in name of file
  name = fxpar(original_header, 'NAME')
  ;removing zeros in the strings
  aot = strcompress(long_aot, /remove_all)

;NOTE will need to edit this to work with my darks
  if (expid eq 1) then begin
    fits_read, '/Users/helen/Documents/AKARI/dark/iraf_dark/processed/image/processed_' +detector +'_short.fits', dark_image, dark_header
    endif else begin
      fits_read, '/Users/helen/Documents/AKARI/dark/idl_images/processed/image/processed_idl_' +detector +'_long.fits', dark_image, dark_header
      endelse

  ;These dark images have already been through normalising & linearity step

  ;setting lower value for the images
  lower = -1000.0D
  ;setting upper value for the images
  upper = 10000.0D

  ;selecting the area of the original to find mean, median & mode
  if(detector eq 'NIR') then begin
    original_image_area = original_image[0:411, 396:511]
    endif else begin
      if(detector eq 'MIRS') then begin
        original_image_area = original_image[0:19, 0:255]
        endif else begin
          if(detector eq 'MIRL') then begin
            original_image_area = original_image[245:255, 81:199]
            endif else print, 'Detector not found'
            endelse
            endelse

  ;calculating the mode for the image
  ;setting inital sigma
  original_initial_sigma = stddev(original_image_area)
  ;removing pixels which have flux less than lower, and greater than upper
  lower = -1000.0
  upper = 10000.0
  bad_pixel_lower = where(original_image_area lt lower, complement = good_pixel_lower)
  ;darkshift = mean(dark_image_area[good_pixel_lower])
  original_image_area = original_image_area[good_pixel_lower] 
  bad_pixel_upper = where(original_image_area gt upper, complement = good_pixel_upper)
  ;darkshift = mean(dark_image_area[good_pixel_upper])
  original_image_area= original_image_area[good_pixel_upper]
  ;sigma clipping, aka leaving out pixels which are 2sigma away from the mean
  ;iteration = 20
  ;set initial value
  ;iteration = 0
  for count = 0, 21 do begin
  ;while (iteration lt 21) do begin
    ;finding the sd of the image[area]
    sigma = stddev(original_image_area)
    ;finding the mean of the image[area]
    mean = mean(original_image_area)
    ;max/min values for pixels
    min_value = mean - (2.0 * sigma)
    max_value = mean + (2.0 * sigma)
    ;getting rid of pixels not within max/min
    bad_pixel_small = where(original_image_area lt min_value, complement = good_pixel_small)
    original_image_area = original_image_area[good_pixel_small]
    bad_pixel_big = where(original_image_area gt max_value, complement = good_pixel_big)
    original_image_area = original_image_area[good_pixel_big]
    ;iteration = iteration + 1
    ;endwhile
    endfor

  ;finding the mode using sky_stats
  sky_stats, original_image_area, mode_original_image, binsize = 0.1 * original_initial_sigma

   ;finding mode for dark image
   if(detector eq 'NIR') then begin
    if(expid eq 1) then begin
      mode_dark_image = NIR_short
      endif else begin
        mode_dark_image = NIR_long
        endelse
        endif else begin
          if(detector eq 'MIRS') then begin
            if(expid eq 1) then begin
              mode_dark_image = MIRS_short
              endif else begin
                mode_dark_image = MIRS_long
                endelse
                endif else begin
                if(detector eq 'MIRL') then begin
                  if(expid eq 1) then begin
                    mode_dark_image = MIRL_short
                    endif else begin
                      mode_dark_image = MIRL_long
                      endelse
                      endif else begin
                        print, 'error with detector and or expid name'
                        endelse
                        endelse
                        endelse

  darkshift_mode = mode_original_image - mode_dark_image
  new_image1 = original_image - dark_image
  new_image = new_image1 - darkshift_mode

  ;Editing the headers
  sxaddpar, original_header, "DARK", "DONE"
  sxaddpar, original_mask_header, "DARK", "DONE"
  sxaddpar, original_noise_header, "DARK", "DONE"
    
  ;message to say step has been done on specific image
  print, 'File ', name, " has been through dark step"
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

end
