pro linearity, image_array, edited_image_array

; Purpose
;      This is to be used with akari_pipeline
;      To replicate the linearity step done in the irc pipeline.
;      This scales the value of a pixel flux, if the flux > 1000
;      Scaled by a different amount for NIR, MIRS & MIRL
;      Note I have rememoved the zeros in the string for aot
;      & detector read in from header
;      fits which have been through linearity should have 'LINEARIT' = 'DONE' in header
;      The 1st 4 pixels in the X001 images are very big, possible 
;Calling sequence:
;     linearity, image_array, edited_image_array
;Inputs:
;     array_image - array of structures, each containing information about an image
;Outputs:
;     edited_image_array - array of structures after its been through linearity step
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
;setting constants for the polynomial
if (detector eq 'NIR') then begin
    b = 1.0288217D0
    c = -4.0339674e-05
    d = 1.3556758e-08
    e = -1.5086542e-12
    f = 5.9679544e-17
    g = 0.0
    h = 0.0
    j = 0.0
    k = 0.0
endif else begin
   if(detector eq 'MIRS') then begin
      b = 1.0117087D0
      c = -1.3870478e-05
      d = 3.4618232e-09
      e = -2.1041555e-13
      f = 4.5837121e-18
      g = 0.0
      h = 0.0
      j = 0.0
      k = 0.0
  endif else begin
      if(detector eq 'MIRL') then begin
         b = 1.0220690D0
         c = -3.1492003e-05
         d = 1.1540795e-08
         e = -1.6499665e-12
         f = 1.1428071e-16
         g = -3.6875836e-21
         h = 4.4799597e-26
         j = 0.0
         k = 0.0
      endif else print, 'error with detector name'
   endelse
endelse

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

  ;reading in name of file
  name = fxpar(original_header, 'NAME')  
  ;reading in linvar value
  ;linver = fxpar(original_header, 'LINVER')

;selecting pixels whose flux > 1000
scale_flux= where(original_image gt 1000.0)
new_image = original_image
  ;scaling selected pixels in output image
  new_image[scale_flux] = double(original_image[scale_flux]*b) + double((original_image[scale_flux]^(2.0))*c) + $
    double((original_image[scale_flux]^(3.0))*d) + double((original_image[scale_flux]^(4.0))*e) + $
    double((original_image[scale_flux]^(5.0))*f)
   
  ;Edit headers
  sxaddpar, original_header, "LINEARIT", "DONE"
  sxaddpar, original_mask_header, "LINEARIT", "DONE"
  sxaddpar, original_noise_header, "LINEARIT", "DONE"
    
  ;message to say step has been done on specific image
  print, 'File ', name, " has been through linearity step"

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