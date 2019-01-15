pro wrap, image_array, edited_image_array

; Purpose
;      This is to be used with akari_pipeline
;      To replicate the wraparound step done in the irc pipeline.
;      For pixels with values < -11953.8, a + (2 ^ (16.0))
;      This is the same for the three filters: NIR, MIRS & MIRL
;      fits which have been through wraparound should have 'WRAP' = 'DONE' in header
;Calling sequence:
;     wrap, image_array, edited_image_array
;Inputs:
;     image_array - array of structures, each containing information about an image
;Outputs:
;     edited_image_array - array of sructures, after it's been through wraparound step
;Keywords:
;     none
;Author & history:
;     Helen Davidge 2013
;     Edit Helen Davidge 2 Dec 2013 to include masking bloomed pixels

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
  wrap_pixel = where(original_image le -11953.8)

  ;checking that wrap_pixel does not = -1
  wrap_array = size(wrap_pixel)
  bad_pixel = wrap_array[2]

  new_image = original_image
  
   if (bad_pixel eq 1) then begin
    print, 'File ', name, ' has no pixels to wraparound'
    ;edit headers
    sxaddpar, original_header, "WRAP", "DONE", "image not changed"  
    sxaddpar, original_mask_header, "WRAP", "DONE", "image not changed"
    sxaddpar, original_noise_header, "WRAP", "DONE", "image not changed"
  endif else begin
      new_image[wrap_pixel] = original_image[wrap_pixel] + (2 ^ (16.0))
      
      ;creating a wrap mask
      num_wrap_pix = size(wrap_pixel, /n_elements)

      for count = 0, (num_wrap_pix -1) do begin
        wrap_pix_count = wrap_pixel[count]
        
        num_rows = wrap_pix_count / xsize
        num_columns = wrap_pix_count - (num_rows * xsize)
        x_value = num_columns
        y_value = num_rows
        
        ;masking all pixels in the column
        original_mask[x_value, *] = 5
 
        ;checking warp_pix is not in the top 2 rows of the image
        max_wrap_pixel = xsize * (ysize - 2.0) 
        if(wrap_pix_count lt max_wrap_pixel) then begin                      
          ;masking every 4 pixels after wraparound for the next xsize pixels
          for n = 1.0, (((xsize * 2) -1 )/ 4) do begin
            ;Because sensor had 4 output nodes
            new_location = wrap_pix_count + (4.0 * n)
            ;mask pixel at new location
            original_mask[new_location] = 5
          endfor
        
          ;mask every four pixels between xsize and 2*xsize after the wrapped pixel
          for q = ((1 + xsize) / 4 ) , (((xsize * 2) - 1) / 4) do begin
            ;Because sensor had 4 output nodes
            new_location = wrap_pix_count + 1 + (4.0 * q)
            ;mask pixel at new location
            original_mask[new_location] = 5
          endfor  
        endif   
      endfor
     
      ;check the location of original_mask = 5, that not all/nearly all of its
      ;eight nearest neighbours are also bad pixels. Giving them a different value
      ;in original_mask, as using the mean value for them in mean_value_mask_pixels
      ;does not work!
      
      ;create a copy of original_mask
      temp_mask = original_mask
      
      ;create an array to hold the locations where original_mask = 5
      array_mask = where(original_mask gt 4.5)
      num_array_mask = size(array_mask, /n_elements)
      ;make a copy of mask array
      temp_array_mask = array_mask     
      
      ;go through array_mask one at a time
      for q = 0, (num_array_mask -1) do begin
        array_mask_pixel = array_mask[q]
        mask_num_rows = array_mask_pixel / xsize
        mask_num_columns = array_mask_pixel - (mask_num_rows * xsize)
        mask_x_value = mask_num_columns
        mask_y_value = mask_num_rows

        ;not selecting the top or bottom row, as this does not work with mask pixel = 11
        if(mask_y_value lt (ysize - 2) and mask_y_value gt 1) then begin  
          ;pixel x (where x has been flagged as a 5) is flagged as 6 if: blank, X, 5      
          if(temp_mask[array_mask_pixel + 1] eq 5) then begin
            original_mask[array_mask_pixel] = 6
          endif

          ;pixel x is flagged as 7 if: 5, x, blank
          if(temp_mask[array_mask_pixel - 1] eq 5) then begin
            original_mask[array_mask_pixel] = 7
          endif 
        
          ;pixel x is flagged as 8 if: 5, x, 5
          if(temp_mask[array_mask_pixel + 1] eq 5 and temp_mask[array_mask_pixel - 1] eq 5) then begin
            original_mask[array_mask_pixel] = 8
          endif
        
          ;pixel x is flagged as 9 if: 5, 5, x, 5, 5
          if(temp_mask[array_mask_pixel + 1] eq 5 and temp_mask[array_mask_pixel - 1] eq 5 $
            and temp_mask[array_mask_pixel + 2] eq 5 and temp_mask[array_mask_pixel - 2]  eq 5) then begin
            original_mask[array_mask_pixel] = 9
          endif 
        
          ;pixel x is flagged is 10 if: 5, 5, 5, x, 5, 5, 5    
          if(temp_mask[array_mask_pixel + 1] eq 5 and temp_mask[array_mask_pixel - 1] eq 5 $
            and temp_mask[array_mask_pixel + 2] eq 5 and temp_mask[array_mask_pixel - 2]  eq 5 $
            and temp_mask[array_mask_pixel + 3] eq 5 and temp_mask[array_mask_pixel - 3]  eq 5) then begin
            original_mask[array_mask_pixel] = 10
          endif
        
          ;                                      5
          ;pixel x is flagged is 11 if: 5, 5, 5, x, 5, 5, 5 
          ;                                      5
          if(temp_mask[array_mask_pixel + 1] eq 5 and temp_mask[array_mask_pixel - 1] eq 5 $
            and temp_mask[array_mask_pixel + 2] eq 5 and temp_mask[array_mask_pixel - 2]  eq 5 $
            and temp_mask[array_mask_pixel + 3] eq 5 and temp_mask[array_mask_pixel - 3]  eq 5 $
            and temp_mask[array_mask_pixel + xsize] eq 5 and temp_mask[array_mask_pixel - xsize] eq 5) then begin
            original_mask[array_mask_pixel] = 11
          endif    
        
          ;                                      5          
          ;                                      5
          ;pixel x is flagged is 12 if: 5, 5, 5, x, 5, 5, 5 
          ;                                      5  
          ;                                      5
          if(temp_mask[array_mask_pixel + 1] eq 5 and temp_mask[array_mask_pixel - 1] eq 5 $
            and temp_mask[array_mask_pixel + 2] eq 5 and temp_mask[array_mask_pixel - 2]  eq 5 $
            and temp_mask[array_mask_pixel + 3] eq 5 and temp_mask[array_mask_pixel - 3]  eq 5 $
            and temp_mask[array_mask_pixel + xsize] eq 5 and temp_mask[array_mask_pixel - xsize] eq 5 $
            and temp_mask[array_mask_pixel + (xsize * 2)] eq 5 and temp_mask[array_mask_pixel - (xsize * 2)]) then begin
            original_mask[array_mask_pixel] = 12
          endif          
        endif
      endfor 

      print, 'File ', name, " has been through wraparound step"
      ;Edit headers
      sxaddpar, original_header, "WRAP", "DONE"
      sxaddpar, original_mask_header, "WRAP", "DONE"
      sxaddpar, original_noise_header, "WRAP", "DONE"
      endelse
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