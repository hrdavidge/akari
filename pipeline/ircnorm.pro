pro ircnorm, image_array, edited_image_array

; Purpose
;      This is to be used with akari_pipeline
;      To replicate the ircnorm step done in the irc pipeline.
;      Note I have rememoved the zeros in the string for aot
;      & detector read in from header
;      fits which have been through normalisation should have 'NORM' = 'DONE' in header
;Calling sequence:
;     ircnorm, array_image, edited_array_image
;Inputs:
;     array_image - array of structures, each containing information about an image
;Outputs:
;     edited_image_array - array of structures after it's been through IRC normalisation step
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

  ;reading in filter
  long_aot = fxpar(original_header, 'AOT')
  ;reading in exposure length
  expid = fxpar(original_header, 'EXPID')
  ;reading in name of file
  name = fxpar(original_header, 'NAME')
  ;removing zeros in the strings
  aot = strcompress(long_aot, /remove_all)

  ;Fowler sampling
  if(detector eq 'NIR') then begin
    if(expid eq 1) then begin
      if(aot eq 'IRC05') then begin
        new_image = original_image * 4.0
      endif else begin
           new_image = original_image
        endelse 
    endif else begin
         new_image = original_image * 0.25
       endelse
  endif else begin
       if(expid eq 1) then begin
         new_image = original_image * 4.0
       endif else begin
            new_image = original_image
         endelse
    endelse
  
  ;Editing headers
  sxaddpar, original_header, "NORM", "DONE"
  sxaddpar, original_mask_header, "NORM", "DONE"
  sxaddpar, original_noise_header, "NORM", "DONE"
    
  ;message to say step has been done on specific image
  print, 'File ', name, " has been through normalisation step"

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
