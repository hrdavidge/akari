pro flat, image_array, edited_image_array

; Purpose
;      This is to be used with akari_pipeline
;      To replicate the flat step done in the irc pipeline, but using bespoke flats created in creating_flat.pro
;      I have changed date-ref read in from header from yyyy-mm-ddThh:mm:ss
;      to yyyymmdd
;      The program then selects the correct flat.fits from: /Users/helen/Documents/AKARI/flat/images/
;      image/flat, all nans are set to the value of -9999.90
;      The corresponding pixels in mask have been given the value 4
;      fits which have been through flat should have 'FLAT' = 'DONE' in header
;      This is the same as IRAF calculated when subtract constant sky = no
;      & subtact scattered light pattern in L15 & L24 = no
;Calling sequence:
;     flat, image_array, edited_image_array
;Inputs:
;     array_image - array of structures, each containing information about an image
;Outputs:
;     edited_image_array - array of structures after its been through flat step
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

;reading in filter
long_filter = fxpar(image_array[0].header, 'FILTER')
;removing zeros in the strings
filter = strcompress(long_filter, /remove_all)

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

  ;reading in date image taken
  long_date = fxpar(original_header, 'DATE-REF')
  ;reading in name of file
  name = fxpar(original_header, 'NAME')
  ;removing zeros in the strings
  ;getting date into yyyymmdd
  ;this is assuming DATE-REF is in the form: yyyy-mm-ddThh:mm:ss
  date1 = strmid(long_date, 0, 10)
  date2 = strsplit(date1, '-', /EXTRACT, /REGEX)
  date3 = date2[0] + date2[1] + date2[2]
  date = double(date3)

  ;sort date
  if(date lt 20060501) then phase ='phase0'
  if(date ge 20060501 and (date lt 20061001)) then phase = 'phase1'
  if(date ge 20061001 and (date lt 20070901)) then begin
;    if(filter eq 'N2') then phase = 'old_phase2'
    
;    if(filter eq 'N3') then phase = 'phase2'
;    if(filter eq 'N3') then phase = 'adfs_2007-02-01_2007-02-09'
    
;    if(filter eq 'N4') then phase = 'phase2'
;    if(filter eq 'N4') then phase = 'irac_2006-10-20_2006-10-31'
;    if(filter eq 'N4') then phase = 'adfs_2007-02-01_2007-02-09'
;    if(filter eq 'N4') then phase = 'irac_2007-04-13_2007-04-25'
;    if(filter eq 'N4') then phase = 'elais_2007-07-15_2007-07-24'
    
;    if(filter eq 'S7') then phase = 'phase2'
;    if(filter eq 'S7') then phase = 'adfs_2007-02-01_2007-02-09'
        
;    if(filter eq 'S9W') then phase = 'phase2'

    
;    if(filter eq 'S11') then phase = 'phase2
;    if(filter eq 'S11') then phase = 'irac_2006-10-17_2006-10-19'
;    if(filter eq 'S11') then phase = 'irac_2006-10-26_2006-10-29'
;    if(filter eq 'S11') then phase = 'adfs_2007-02-01_2007-02-09'
;    if(filter eq 'S11') then phase = 'irac_2007-04-13_2007-04-25'
;    if(filter eq 'S11') then phase = 'elais_2007-07-15_2007-07-24'
    
;    if(filter eq 'L15') then phase = 'irac_phase1'
;    if(filter eq 'L15') then phase = 'phase2'
;    if(filter eq 'L15') then phase =  'elais_2007-01-12_2007-01-21'
;    if(filter eq 'L15') then phase = 'adfs_2007-02-01_2007-02-09'
    if(filter eq 'L15') then phase = 'hudf_2007-01-26_2007-02-05'
;    if(filter eq 'L15') then phase = 'irac_2007-04-13_2007-04-25'    
;    if(filter eq 'L15') then phase = 'irac_2007-05-13_2007-05-16'    
;    if(filter eq 'L15') then phase = 'elais_2007-07-15_2007-07-24'
;    
;    if(filter eq 'L18W') then phase = 'phase2'
;    if(filter eq 'L18W') then phase = 'irac_2006-10-01_2006-10-10'
;    if(filter eq 'L18W') then phase = 'elais_2007-07-15_2007-07-24'
;    if(filter eq 'L18W') then phase = 'irac_2007-04-13_2007-04-25'

;    if(filter eq 'L24') then phase = 'phase2'
;    if(filter eq 'L24') then phase = 'adfs_2007-02-01_2007-02-09'

  endif
  if(date ge 20070901 and (date lt 20080200)) then phase = 'phase3a'
  if(date ge 20080200 and (date lt 20080800)) then phase = 'phase3b'
  if(date ge 20080800 and (date lt 20090200)) then phase = 'phase3c'
  if(date ge 20090200 and (date lt 20090800)) then phase = 'phase3d'
  if(date ge 20090800 and (date lt 20100200)) then phase = 'phase3e'
  if(date ge 20100200 and (date lt 20100800)) then phase = 'phase3f'
  if(date ge 20100800 and (date lt 20100200)) then phase = 'phase3g'
  if(date ge 20100200 and (date lt 20100800)) then phase = 'phase3h'
  if(date ge 20100800 and (date lt 20101231)) then phase = 'phase3i'

  ;selecting the correct flat
  fits_read, '/Users/helen/Documents/AKARI/flat/images/' + filter + '/' + phase + '_flat.fits', flatfield_image, flatfield_header
  ;ISAS flat for removing bean from S11 IRAC images
;;;  fits_read, '/Users/helen/iraf/irc/lib/flat/soramame-ari/S11.fits', flatfield_image, flatfield_header
; fits_read, '/Users/helen/Documents/AKARI/ISAS/newflat/p23/S11.fits', flatfield_image, flatfield_header
; fits_read, '/Users/helen/Documents/AKARI/bad_pixels/L15/2007-07-15_2007-07-24/flat_raw_images.fits', flatfield_image, flatfield_header

;new_image1 = original_image / flatfield_image
    if(filter eq 'N2') then new_image1 = original_image / flatfield_image
    if(filter eq 'N3') then new_image1 = original_image / flatfield_image
    if(filter eq 'N4') then new_image1 = original_image / flatfield_image
    if(filter eq 'S7') then new_image1 = original_image / flatfield_image
    ;if(filter eq 'S7') then new_image1 = original_image / (flatfield_image ^ 1.2)
    if(filter eq 'S9W') then new_image1 = original_image / flatfield_image
    if(filter eq 'S11') then new_image1 = original_image / flatfield_image
    ;if(filter eq 'S11') then new_image1 = original_image / (flatfield_image ^ 1.05)
    if(filter eq 'L15') then new_image1 = original_image / flatfield_image
    ;if(filter eq 'L15') then new_image1 = original_image / (flatfield_image ^ 1.05)
    if(filter eq 'L18W') then new_image1 = original_image / flatfield_image
    ;if(filter eq 'L18W') then new_image1 = original_image / (flatfield_image ^ 1.05)
    if(filter eq 'L24') then new_image1 = original_image / flatfield_image
    ;if(filter eq 'L24') then new_image1 = original_image / (flatfield_image ^ 1.12)


;if(filter eq 'L15') then begin
  ;this is to correct for Earth shine light
  ;Need to investigate this this is the correct power for other L15 images
;  new_image1 = original_image / (flatfield_image ^ 1.05)
;endif else begin
;  if(filter eq 'S7') then begin
    
;  endif else begin
 ; if(filter eq 'L24') then begin
;    new_image1 = original_image / (flatfield_image ^ 1.12)
;  endif else begin
;    if(filter eq 'L18W') then begin
;      new_image1 = original_image / (flatfield_image ^ 1.05)
;    endif else begin  
      ;I wil probably need to scale flat by a power in other filters as well
;      new_image1 = original_image / flatfield_image
;    endelse
; endelse
;endelse
;endelse
  ;checking for nans
  bad_pixels = where(finite(new_image1) eq 0, nbad)
  new_image = new_image1
  ;setting all nans to 0
  new_image[bad_pixels] = -9999.90
  
  ;marking the positions of the bad pixels on the mask image
  new_mask = original_mask
  ;setting bad pixels to value = 1 in mask image
  new_mask[bad_pixels] = 4

  ;Editing the head to say it has been through flat step
  sxaddpar, original_header, "FLAT", "DONE", "for pixels dev by zero see mask image"
  sxaddpar, original_mask_header, "FLAT", "DONE", "flagged pixels = 4"
  sxaddpar, original_noise_header, "FLAT", "DONE"
    
  ;message to say step has been done on specific image
  print, 'File ', name, " has been through flat step"
  
  ;load edited information into the new structure
  new_image_array[i].image = new_image
  new_image_array[i].header = original_header
  new_image_array[i].mask_image = new_mask
  new_image_array[i].mask_header = original_mask_header
  new_image_array[i].noise = original_noise
  new_image_array[i].noise_header = original_noise_header
  new_image_array[i].history = original_history
endfor

edited_image_array = new_image_array
end
