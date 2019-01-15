pro akari_idl_prepipeline, input_directory = input_directory, output_directory, dark, create_dir

;Purpose:
;     To sort fits files into exposure length and then into the 9 different filters within a directory
;     This program will create sub-directories in output_directory: /short and /long
;     Within /short and /long the program will create 9 sub-directories, one for each filter
;     If there is no output_directory, the program will create sub-directories in input_directory
;     The program will go thorugh the images in input_directory, one at a time and
;     write the image to the correct sub-directory
;     Note: if the key word dark is set, the program will create the sub-dircetory dark
;     and put all dark images in there.
;     ;NOTE might need to edit this so it fliters out UNDIF images
;     NOTE the dark and create_dir keywords don't work, so I have commented them out
;     NOTE Spectrospic images are not binned in any directory
;Calling sequence:
;     akari_idl_pipeline, input_directory = input_directory, output_directory, dark
;Inputs:
;     input_directory - path to directory containing the fits files to sort into different filters
;Optional inputs
;     output_directory - path to directory to put files in
;Outputs:
;     none
;Keywords:
;     dark
;     create_dir
;Author & history:
;     Helen Davidge 16th Dec 2013, OU
;     

if(n_elements(input_directory) eq 0) then print, "ERROR: input_directory parameter required"

if(n_elements(output_directory) eq 0) then output_directory = input_directory

;if(keyword_set(create_dir)) then begin
;create sub-directories
;create long and short exposure directories
file_mkdir, output_directory + '/short'
file_mkdir, output_directory + '/long'
;create directories to put short images in
file_mkdir, output_directory + '/short/N2'
file_mkdir, output_directory + '/short/N3'
file_mkdir, output_directory + '/short/N4'
file_mkdir, output_directory + '/short/S7'
file_mkdir, output_directory + '/short/S9'
file_mkdir, output_directory + '/short/S11'
file_mkdir, output_directory + '/short/L15'
file_mkdir, output_directory + '/short/L18'
file_mkdir, output_directory + '/short/L24'
;create directories to put long images in
file_mkdir, output_directory + '/long/N2'
file_mkdir, output_directory + '/long/N3'
file_mkdir, output_directory + '/long/N4'
file_mkdir, output_directory + '/long/S7'
file_mkdir, output_directory + '/long/S9'
file_mkdir, output_directory + '/long/S11'
file_mkdir, output_directory + '/long/L15'
file_mkdir, output_directory + '/long/L18'
file_mkdir, output_directory + '/long/L24'
;if(keyword_set(dark)) then begin
   file_mkdir, output_directory + '/short/dark'
   file_mkdir, output_directory + '/long/dark'
;endif
;endif

;creating array 'list' to hold all the fits in the input_directory passed to the program
list = file_search(input_directory, "*.fits")
array = size(list)
if(array(0) eq 0) then print, "ERROR: No fits in input_directory or path incorrect"
sizeoflist = array(3)

;so list_with_path works
cd, input_directory
;creating an array to hold the fits names
file_name = list_with_path("*.fits", input_directory)

for i = 0, (sizeoflist - 1) do begin
   fits_read, list[i], image, header
   ;reading in exposure length
   expid = fxpar(header, 'EXPID')
   ;reading in filter
   long_filter = fxpar(header, 'FILTER')
   ;removing zeros in the strings
   filter = strcompress(long_filter, /remove_all) 
   
   ;putting the image in the correct sub-directory
   if(expid eq 1) then begin
;     if(filter eq 'N2') then writefits, output_directory + '/short/N2/' + file_name[i], image, header
;     if(filter eq 'N3') then writefits, output_directory + '/short/N3/' + file_name[i], image, header
;     if(filter eq 'N4') then writefits, output_directory + '/short/N4/' + file_name[i], image, header
;     if(filter eq 'S7') then writefits, output_directory + '/short/S7/' + file_name[i], image, header
;     if(filter eq 'S9W') then writefits, output_directory + '/short/S9/' + file_name[i], image, header     
;     if(filter eq 'S11') then writefits, output_directory + '/short/S11/' + file_name[i], image, header     
;     if(filter eq 'L15') then writefits, output_directory + '/short/L15/' + file_name[i], image, header
;     if(filter eq 'L18W') then writefits, output_directory + '/short/L18/' + file_name[i], image, header          
;     if(filter eq 'L24') then writefits, output_directory + '/short/L24/' + file_name[i], image, header 
;     if(keyword_set(dark)) then begin    
;     if(filter eq 'DARK') then writefits, output_directory + '/short/dark/' + file_name[i], image, header  
;     endif   
   endif else begin
;     if(filter eq 'N2') then writefits, output_directory + '/N2/1320232_007/raw_images/' + file_name[i], image, header
;     if(filter eq 'N3') then writefits, output_directory + '/N3/1320235_005/raw_images/' + file_name[i], image, header
;     if(filter eq 'N4') then writefits, output_directory + '/N4/1320232_001/raw_images/' + file_name[i], image, header
;     if(filter eq 'S7') then writefits, output_directory + '/S7/1320235_005/raw_images/' + file_name[i], image, header 
;     if(filter eq 'S9W') then writefits, output_directory + '/S9W/1320232_007/raw_images/' + file_name[i], image, header
;     if(filter eq 'S11') then writefits, output_directory + '/S11/1320232_001/raw_images/' + file_name[i], image, header     
;     if(filter eq 'L15') then writefits, output_directory + '/L15/1320235_005/raw_images/' + file_name[i], image, header  
;     if(filter eq 'L18W') then writefits, output_directory + '/L18W/1320232_007/raw_images/' + file_name[i], image, header     
;     if(filter eq 'L24') then writefits, output_directory + '/L24/1320232_001/raw_images/' + file_name[i], image, header 
     if(filter eq 'N2') then writefits, output_directory + '/long/N2/' + file_name[i], image, header
     if(filter eq 'N3') then writefits, output_directory + '/long/N3/' + file_name[i], image, header
     if(filter eq 'N4') then writefits, output_directory + '/long/N4/' + file_name[i], image, header
     if(filter eq 'S7') then writefits, output_directory + '/long/S7/' + file_name[i], image, header
     if(filter eq 'S9W') then writefits, output_directory + '/long/S9/' + file_name[i], image, header     
     if(filter eq 'S11') then writefits, output_directory + '/long/S11/' + file_name[i], image, header     
     if(filter eq 'L15') then writefits, output_directory + '/long/L15/' + file_name[i], image, header
     if(filter eq 'L18W') then writefits, output_directory + '/long/L18/' + file_name[i], image, header          
     if(filter eq 'L24') then writefits, output_directory + '/long/L24/' + file_name[i], image, header    
     if(keyword_set(dark)) then begin 
     if(filter eq 'DARK') then writefits, output_directory + '/long/dark/' + file_name[i], image, header  
     endif   
   endelse

    if(filter eq '0') then print, 'ERROR no filter information in header for image: ', file_name[i]
endfor

;code to call pro akari_pipeline
print, 'code to call AKARI pipeline:'
print, "pro akari_pipeline, directory = '", output_directory, "/long/XX', all = all"
end