function [] = spherical_kernel_intensity_estimator(ryrfile,im_spatres,cellPath,r_sphere,hval)
%a matlab program to use Diggle 1983 spherical window to estimate intensity
%distribution of a 3d point pattern
progressbar;
%% input paramters for kernel intensity smoothing

meshName = 'combined_tet_mesh_wryrgap';
h = [hval,hval,hval]; %spatial step to be taken in x,y,z to do the intensity estimate
progressbar(1/7);
%% Parameters for RyR calcium release simulation

initial_release_point= 30;%the initial points from which calcium is release. By default, we could have initial_releas_nodes=ryr_release
tau_lag = 6.7; %based on Wang 2001 paper in Nature Letters
tausimnum = '1';

%gaussian parameters to be set up for assigning strength of release

sigma = [0.1 0.1 0.1];
Amp = 1.0;
progressbar(2/7);

%% load in the simulated RyR points.

fid = fopen(ryrfile,'r');
%header=fgetl(fid); used to read header from an older simulated ryr points
%file version (blumgart version as opposed to cam version)
ryrPoints = [];
point=0;
while(feof(fid)==0)
    point = point+1;
    ryrPoints(point,:) = str2num(fgetl(fid));
end 
fclose(fid);
progressbar(3/7);

%% read in the nodes of the generated mesh
%read in the generated node and ele files
nodefile = strcat(cellPath,meshName,'.node');
elefile = strcat(cellPath,meshName,'.ele');
fid = fopen(nodefile,'r');
nodesHeader = str2num(fgetl(fid));
meshNodes = zeros(nodesHeader(1),5);
node = 0;
while(feof(fid)==0 && node<nodesHeader(1))
    node=node+1;
    meshNodeValues = str2num(fgetl(fid));
    meshNodes(node,1) = (meshNodeValues(1));
    meshNodes(node,2) = meshNodeValues(2);
    meshNodes(node,3) = meshNodeValues(3);
    meshNodes(node,4) = meshNodeValues(4);
    meshNodes(node,5) = (meshNodeValues(5));
    
end
fclose(fid);
progressbar(4/7);

%% setting up time lags and Popen for release from each node.

node_timelags = zeros(nodesHeader(1),1);
node_Popens = zeros(nodesHeader(1),1);
%pick value between 0 and 1 randomly for each of the ryr cluster points.
ryrPoint_timelags = exprnd(tau_lag,size(ryrPoints,1),1);
progressbar(5/7);

%% evaluate the ryr cluster point intensity at each of these mesh nodes using
%the gaussian function.
node_ryr_kie = zeros(nodesHeader(1),1);
for node = 1:size(node_ryr_kie)
    %simplest interpolation is to round the co-ordinates to those of the
    %grid points at which ryr_kie have been evaluated
    %k = round(meshNodes(node,4)/h(3)+1);
    %j = round(meshNodes(node,3)/h(3)+1);    
    %i = round(meshNodes(node,2)/h(3)+1);
    sphere_centerx = meshNodes(node,2);
    sphere_centery = meshNodes(node,3);
    sphere_centerz = meshNodes(node,4);
    %with node as centre, determine if ryrs are within the radius
    %neighborhood of the node.
    
    for point = 1:size(ryrPoints,1)
        pointx = ryrPoints(point,2);
        pointy = ryrPoints(point,1);
        pointz = ryrPoints(point,3);
% 
        rsquared = (pointx-sphere_centerx)^2+(pointy-sphere_centery)^2+(pointz-sphere_centerz)^2;
        if(rsquared<=(r_sphere)^2) %check if distance between ryr point and sphere center is within radius of sphere.
            exponent = ((sphere_centerx-pointx)^2)/(2*(sigma(1))^2) + ((sphere_centery-pointy)^2)/(2*(sigma(2))^2) + ((sphere_centerz-pointz)^2)/(2*(sigma(3))^2);
            node_ryr_kie(node,1) = node_ryr_kie(node,1)+Amp*exp(-exponent);
            %assign the same time lag to the mesh node as the nearest ryr
            %cluster point
            node_timelags(node,1) = ryrPoint_timelags(point,1);
            if(point==initial_release_point)
                node_Popens(node,1) = 0.05;
            end
        end
    end
   
end
%write out the kie's at these nodes to a file; adding time lag to this
%file.
outfile = strcat(cellPath,meshName,'_spherical_ryr_kie_wh',num2str(hval),'.','_N123_fixedNNd_tausimnum_',tausimnum,'.txt');
disp('writing out mesh intensity estimates');
fid = fopen(outfile,'w+');
node_kie_timelags = [node_ryr_kie,node_timelags];
fprintf(fid,'%f\t%f\n',node_kie_timelags');
fclose(fid);
progressbar(6/7);

%% export as mesh and ryr intensities as exnode,exelem,exdata files too.

outfile = strcat(cellPath,meshName,'_spherical_ryr_kie_wh',num2str(hval),'.','_N123_fixedNNd.exdata');

[fid, msg] = fopen(outfile, 'w', 'native');
fprintf (fid,'Group name: Cell_RyRDensity\n#Fields=4\n1) coordinates, coordinate, rectangular cartesian, #Components=3\n x.  Value index=1, #Derivatives=0\n y.  Value index=2, #Derivatives=0\n z.  Value index=3, #Derivatives=0\n2) ryrdensity,field,rectangular cartesian, #Components=1\n density. Value index= 4, #Derivatives=0\n3) Popen,field,rectangular cartesian, #Components=1\n p. Value index= 5, #Derivatives=0\n4) TimeLags,field,rectangular cartesian, #Components=1\n lag. Value index= 6, #Derivatives=0\n');
for i = 1:size(node_ryr_kie,1)
    fprintf (fid,'Node:\t%d\n',i);
    fprintf (fid,'%f\n',(meshNodes(i,2)));
    fprintf (fid,'%f\n',(meshNodes(i,3)));
    fprintf (fid,'%f\n',(meshNodes(i,4)));

    fprintf (fid,'%f\n',(node_ryr_kie(i)));
    fprintf (fid,'%f\n',(node_Popens(i)));
    fprintf (fid,'%f\n',(node_timelags(i)));


end
fclose(fid);
progressbar(7/7);



                    

