pro akari_pipeline, directory = directory, wrap = wrap, dark = dark, norm = norm, $
scatt_light = scatt_light, line = line, ray = ray, anom_pixel = anom_pixel, $
sat = sat, flat = flat, noise = noise, earth_light = earth_light, dewarp = dewarp, all = all

;Purpose:
;     The AKARI pipeline.
;     Note images put through the pipeline must have the same filter.
;     This is passed the path to the directory with the fits files in
;     And then calls the sequences selected by the key words
;     NOTE - The images must all be either NIR, SMIR or LMIR images
;     This must be set at a keyword, otherwise the program won't work!
;     Make sure correct flat has been set in flat
;     note if error message is:
;     Attempt to subscript ARRAY with <INT      (       3)> is out of range
;     This means path is incorrect
;     NOTE need to write dewarp.pro
;Calling sequence:
;     akari_pipeline, directory = directory
;Inputs
;     directory - directory containing fits files to be processed
;Outputs:
;     None
;Keywords:
;     NIR
;     MIR
;     wrap
;     dark
;     norm
;     scatt_light
;     line
;     ray
;     anom_pixel
;     sat
;     flat
;     noise
;     earth_light
;     dewarp
;     all
;Author & history:
;     Helen Davidge 2013

if(n_elements(directory) eq 0) then print, "ERROR: directory parameter required"

;passing path to reading_in.pro to read in the fits files 
;and create the sturcture to hold all the information
reading_in, directory,  master_array

;creating a bespoke flat
;creating_flat, master_array, flat_image
;stop
;creating a bespoke dark
;creating_dark, master_array, dark_image

;going through all of the keywords
if(keyword_set(all)) then begin
  wrap = 1b
  dark = 1b
  norm = 1b
  scatt_light = 1b
  ray = 1b
  line = 1b
  flat = 1b
  anom_pixel = 1b
  sat = 1b
  noise = 1b
  earth_light = 1b
  dewarp = 1b
  endif

if(keyword_set(wrap)) then begin
  wrap, master_array, master_array
  endif

if(keyword_set(dark)) then begin
  dark, master_array, master_array
  endif

if(keyword_set(norm)) then begin
  ircnorm, master_array, master_array
  endif  

;do not perform this step for S7 filter
;if(keyword_set(scatt_light)) then begin
;  scatt_light, master_array, master_array
;  endif

if(keyword_set(line)) then begin
  linearity, master_array, master_array
  endif
 
if(keyword_set(flat)) then begin
  flat, master_array, master_array
  endif

  if(keyword_set(anom_pixel)) then begin
    anom_pix, master_array, master_array
  endif

if(keyword_set(ray)) then begin
  cosmic_ray, master_array, master_array
endif

;;;if(keyword_set(ray)) then begin
;;;    cosmic_ray_using_la_cosmic, master_array, master_array, directory
;;;  endif

  
;giving pixels flagged in mask the mean value of the 8 nearest pixels
mean_value_mask_pixels, master_array, master_array

;dewarping the images and noise images
dewarp, master_array, master_array

if(keyword_set(earth_light)) then begin
  earth_light, master_array, master_array
endif

if(keyword_set(noise)) then begin
   akari_noise, master_array, master_array
endif

;;;nir_dewarping_missing, master_array, master_array

;will need the code from practice_earth_light_2 for S11, L18W & L24

;converting the information in the structure into fits + headers
creating_fits, master_array, directory

end