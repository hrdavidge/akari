pro creating_fits, image_array, directory

; Purpose
;      This is the final step in the akari pipeline
;      This pro reads in each structure & converts it to fits + header
;      The processed inages will be saved in 'directory', called processed_'NAME'
;      text file is created for each image, currently this is commented out
;Calling sequence:
;     creating_fits, image_array, directory
;Inputs:
;     image_array - array of structures, each containing information about an image
;     directory - path to directory containing fits files
;Outputs:
;     none
;Keywords:
;     none
;Author & history:
;     Helen Davidge 2013

;reading in number of structures
numberofstruc = size(image_array, /n_elements)

;creating folders to hold the processed images, masks and noise fits
file_mkdir, directory + '/processed'
file_mkdir, directory + '/processed/image'
file_mkdir, directory + '/processed/mask'
file_mkdir, directory + '/processed/noise'
;file_mkdir, directory + 'prcessed/text_files'

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
  
  ;saving the new image in the 'directory'
  writefits, directory +'/processed/image/processed_' +name, double(original_image), original_header
  writefits, directory +'/processed/mask/processed_mask' +name, original_mask, original_mask_header
  writefits, directory +'/processed/noise/processed_noise' +name, double(original_noise), original_noise_header  
  ;openw, 1, directory + '/processed/text_files/history_' +name '.txt'
  ;printf, 1, history
  ;close, 1

endfor
end
