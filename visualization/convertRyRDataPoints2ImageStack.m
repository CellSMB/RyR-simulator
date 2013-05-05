%Author: Vijay Rajagopal
%Need a way to convert a data cloud of ryr contained in txt files into a 3D image stack for manipulation and 
% visualisation in imageJ

clear all; close all;

mfib_flnm = '/Users/vraj004/Documents/heart/data/soeller/Bass/Cell3_processing&analysis/Rotated_stacks_-6cor_-17sag_interp/cell3_phalloidin_reorient_binary_withDents_vFinal.tif'; % FLNM CHANGED
flnmRyRcld = '/Users/vraj004/Documents/heart/sims/R/camSim/Cell3_data/d_sep_zmod_SR_width_6/cell2on3/simPP10.txt';
flnmRyRcld_img = '/Users/vraj004/Documents/heart/sims/R/camSim/Cell3_data/d_sep_zmod_SR_width_6/cell2on3/sim10_%d.tiff';
delimiterIn = '\t';
headerlinesIn = 1;
ryrPos = importdata(flnmRyRcld, delimiterIn, headerlinesIn);

mfib_info = imfinfo(mfib_flnm);
num_images = numel(mfib_info);
mfib_y = mfib_info(1).Height;
mfib_x = mfib_info(1).Width;
mfib_z = num_images; %*stepSize - 2*distWindowFromEnds; % length of the stack in z-direction, preserving as much information as possible 
ryr_coords = zeros(mfib_y,mfib_x,mfib_z);
res = [0.073216,0.073216,0.053535];
ryrPos_pix = zeros(size(ryrPos.data,1),3);

for i=1:size(ryrPos.data,1)
    ryr_coords(round(1+ryrPos.data(i,2)/res(1)),round(1+ryrPos.data(i,1)/res(2)),round(1+ryrPos.data(i,3)/res(3))) = 255;
    ryrPos_pix(i,:) = [round(1+ryrPos.data(i,2)/res(1)) round(1+ryrPos.data(i,1)/res(2)) round(1+ryrPos.data(i,3)/res(3))];
end



for K=1:mfib_z
   outputfile = sprintf(flnmRyRcld_img,K);
   imwrite(ryr_coords(:, :, K), outputfile,'WriteMode','overwrite');
end