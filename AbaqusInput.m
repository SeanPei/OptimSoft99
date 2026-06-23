function model=AbaqusInput(varargin)
if nargin==0
    [fname,fpath]=uigetfile('*.inp','Select the ABAQUS Model File');
    fileabaqus=strcat(fpath,fname);
else
    fileabaqus=varargin{1};
end
[fin,message]=fopen(fileabaqus,'r');% open inp file
if fin==-1
    error([message,': ',fileabaqus]);
end

global g_element_num g_surface_num

g_element_num=10;
g_surface_num=6;

parts=containers.Map;
assembly=struct;
materials=containers.Map;
boundaries=[];
loads=[];
tline=NextLine(fin);
while 1
    % part
    if strncmp(tline,'*Part',5)
        part=struct;
        % name
        tlinekv=StrKeyValues(tline);
        part.name=tlinekv('name');
        part.nodes=[];
        part.elementtype='';
        part.elements=[];
        part.elset=containers.Map;
        part.nset=containers.Map;
        part.sections=[];
        
        tline=NextLine(fin);
        while ~strncmp(tline,'*End Part',9)
            % nodes
            if strcmp(tline,'*Node')
                tline=NextLine(fin);
                while ~strncmp(tline,'*',1)
                    tnode=textscan(tline,'%f','delimiter',',');
                    part.nodes=[part.nodes,tnode{1}(2:4)];
                    tline=NextLine(fin);
                end
                continue;
            end
            % elements
            if strncmp(tline,'*Element',8)
                tlinekv=StrKeyValues(tline);
                part.elementtype=tlinekv('type');
                tline=NextLine(fin);
                while ~strncmp(tline,'*',1)
                    telement=textscan(tline,'%f','delimiter',',');
                    part.elements=[part.elements,telement{1}(2:g_element_num+1)];
                    tline=NextLine(fin);
                end
                continue;
            end
            % element sets
            if strncmp(tline,'*Elset',6)
                tlinekv=StrKeyValues(tline);
                telsetname=tlinekv('elset');
                telset=[];
                tline=NextLine(fin);
                while ~strncmp(tline,'*',1)
                    telset=[telset,IncreNum(cell2mat(textscan(tline,'%f','delimiter',',')))];
                    tline=NextLine(fin);
                end
                part.elset(telsetname)=telset;
                continue;
            end
            % node sets
            if strncmp(tline,'*Nset',5)
                tlinekv=StrKeyValues(tline);
                tnsetname=tlinekv('nset');
                tnset=[];
                tline=NextLine(fin);
                while ~strncmp(tline,'*',1)
                    tnset=[tnset,IncreNum(cell2mat(textscan(tline,'%f','delimiter',',')))];
                    tline=NextLine(fin);
                end
                part.nset(tnsetname)=tnset;
                continue;
            end
            % solid sections
            if strncmp(tline,'*Solid Section',14)
                tlinekv=StrKeyValues(tline);
                section.elset=tlinekv('elset');
                section.mat=tlinekv('material');
                tline=NextLine(fin);
                while ~strncmp(tline,'*',1)
                    tline=NextLine(fin);
                end
                part.sections=[part.sections,section];
                continue;
            end
            % unsupport lines in part label
            tline=NextLine(fin);
        end
        parts(part.name)=part;
        continue;
    end
    
    if strncmp(tline,'*Assembly',9)
        assembly.instance=containers.Map;
        assembly.cnnelements=[];
        assembly.elset=containers.Map;
        assembly.nset=containers.Map;
        assembly.surface=containers.Map;
        while ~strncmp(tline,'*End Assembly',13)
            % instances
            if strncmp(tline,'*Instance',9)
                tlinekv=StrKeyValues(tline);
                tinsname=tlinekv('name');
                tinspart=tlinekv('part');
                tline=NextLine(fin);
                while ~strncmp(tline,'*End Instance',13)
                    tline=NextLine(fin);
                end
                tline=NextLine(fin);
                assembly.instance(tinsname)=tinspart;
                continue;
            end
            
            % connectors
            if strcmp(tline,'*Element, type=CONN3D2')
                tline=NextLine(fin);
                tcnnelement=struct;
                tcnnnodes=textscan(tline,'%s %s%s %s%s','delimiter',',.');
                tcnnelement.instance1=tcnnnodes{2}{1};
                tcnnelement.node1=str2num(tcnnnodes{3}{1});
                tcnnelement.instance2=tcnnnodes{4}{1};
                tcnnelement.node2=str2num(tcnnnodes{5}{1});
                tline=NextLine(fin);
                assembly.cnnelements=[assembly.cnnelements,tcnnelement];
                continue;
            end
            % surfaces
            if strncmp(tline,'*Surface, type=ELEMENT',22)
                tlinekv=StrKeyValues(tline);
                tsurfname=tlinekv('name');
                tsurface=containers.Map;
                tline=NextLine(fin);
                while ~strncmp(tline,'*',1)
                    tsurfset=textscan(tline,'%s %s','delimiter',',.');
                    tsurface(tsurfset{2}{1})=tsurfset{1}{1};
                    tline=NextLine(fin);
                end
                assembly.surface(tsurfname)=tsurface;
                continue;
            end
            % node sets
            if strncmp(tline,'*Nset',5)
                isinstance = strfind(tline,'instance');
                if isinstance
                    tlinekv=StrKeyValues(tline);
                    tnsetname=tlinekv('nset');
                    tnsetinstance=tlinekv('instance');
                    tnset=[];
                    tline=NextLine(fin);
                    while ~strncmp(tline,'*',1)
                        tnset=[tnset,IncreNum(cell2mat(textscan(tline,'%f','delimiter',',')))];
                        tline=NextLine(fin);
                    end
                    tnodeset=struct;
                    tnodeset.instance=tnsetinstance;
                    tnodeset.nset=tnset;
                    if isKey(assembly.nset,tnsetname)
                        assembly.nset(tnsetname)=[assembly.nset(tnsetname),tnodeset];
                    else
                        assembly.nset(tnsetname)=tnodeset;
                    end
                    continue;
                else
                    tlinekv=StrKeyValues(tline);
                    tnsetname=tlinekv('nset');
                    tnset=[];
                    tline=NextLine(fin);
                    while ~strncmp(tline,'*',1)
                        tnset=[tnset,IncreNum(cell2mat(textscan(tline,'%f','delimiter',',')))];
                        tline=NextLine(fin);
                    end
                    assembly.nset(tnsetname)=tnset;
                    continue;
                end
            end
            % element sets
            if strncmp(tline,'*Elset',6)
                isinstance = strfind(tline,'instance');
                if isinstance
                    tlinekv=StrKeyValues(tline);
                    telsetname=tlinekv('elset');
                    telsetinstance=tlinekv('instance');
                    telset=[];
                    tline=NextLine(fin);
                    while ~strncmp(tline,'*',1)
                        telset=[telset,IncreNum(cell2mat(textscan(tline,'%f','delimiter',',')))];
                        tline=NextLine(fin);
                    end
                    telodeset=struct;
                    telodeset.instance=telsetinstance;
                    telodeset.elset=telset;
                    if isKey(assembly.elset,telsetname)
                        assembly.elset(telsetname)=[assembly.elset(telsetname),telodeset];
                    else
                        assembly.elset(telsetname)=telodeset;
                    end
                    continue;
                else
                    tlinekv=StrKeyValues(tline);
                    telsetname=tlinekv('elset');
                    telset=[];
                    tline=NextLine(fin);
                    while ~strncmp(tline,'*',1)
                        telset=[telset,IncreNum(cell2mat(textscan(tline,'%f','delimiter',',')))];
                        tline=NextLine(fin);
                    end
                    assembly.elset(telsetname)=telset;
                    continue;
                end
            end
            % unsupport lines in assembly label
            tline=NextLine(fin);
        end
        continue;
    end
    
    if strncmp(tline,'*Material',9)
        tlinekv=StrKeyValues(tline);
        tmatname=tlinekv('name');
        tmaterial=struct;
        tline=NextLine(fin);
        if strncmp(tline,'*Density',8)
            tline=NextLine(fin);
            tmatdensity=textscan(tline,'%f','delimiter',',');
            tmatdensity=tmatdensity{1};
            tmaterial.density=tmatdensity;
            tline=NextLine(fin);
        end
        if strncmp(tline,'*Hyperelastic',13)
            tmattype=textscan(tline,'*Hyperelastic, %s');
            tmattype=tmattype{1}{1};
            tmaterial.type=tmattype;
            tline=NextLine(fin);
            if strncmp(tmattype,'neo',3)
                tmatparams=textscan(tline,'%f %f','delimiter',',');
                tmaterial.C10=tmatparams{1};
                tmaterial.D=tmatparams{2};
            elseif strncmp(tmattype,'yeoh',4)
                tmatparams=textscan(tline,'%f%f%f%f%f%f','delimiter',',');
                tmaterial.C10=tmatparams{1};
                tmaterial.C20=tmatparams{2};
                tmaterial.C30=tmatparams{3};
                tmaterial.D=tmatparams{4};
                tmaterial.D1=tmatparams{5};
                tmaterial.D2=tmatparams{6};
            end
            tline=NextLine(fin);
        end
        materials(tmatname)=tmaterial;
        continue;
    end
    
    if strncmp(tline,'*Step',5)
        while ~strncmp(tline,'*End Step',9)
            % boundary condications
            if strncmp(tline,'*Boundary',9)
                tboundary=struct;
                tline=NextLine(fin);
                while ~strncmp(tline,'*',1)
                    tbound=textscan(tline,'%s %s','delimiter',',');
                    tboundary.set=tbound{1}{1};
                    tboundary.type=tbound{2}{1};
                    tline=NextLine(fin);
                end
                boundaries=[boundaries,tboundary];
                continue;
            end
            % loads
            if strncmp(tline,'*Connector',10)
                tload=struct;
                tload.type='Connector';
                tline=NextLine(fin);
                while ~strncmp(tline,'*',1)
                    tbound=textscan(tline,'%s 1, %f','delimiter',',');
                    tload.set=tbound{1}{1};
                    tload.value=tbound{2};
                    tline=NextLine(fin);
                end
                loads=[loads,tload];
                continue;
            end
            if strncmp(tline,'*Dsload',7)
                tload=struct;
                tload.type='Dsload';
                tline=NextLine(fin);
                while ~strncmp(tline,'*',1)
                    tbound=textscan(tline,'%s P, %f','delimiter',',');
                    tload.set=tbound{1}{1};
                    tload.value=tbound{2};
                    tline=NextLine(fin);
                end
                loads=[loads,tload];
                continue;
            end
            % unsupport lines in Step label
            tline=NextLine(fin);
        end
        continue;
    end
    % unsupported lines
    tline=NextLine(fin);
    if tline < 0
        break
    end
end

fclose(fin);
model.parts=parts;
model.assembly=assembly;
model.materials=materials;
model.boundaried=boundaries;
model.loads=loads;

[~,namestr,~]=fileparts(fileabaqus);
ExtractAndSave(namestr,parts,assembly,materials,boundaries,loads);
end

function ExtractAndSave(fname,modparts,modassembly,modmaterials,modboundaries,modloads)
global g_element_num g_surface_num

    partskeys=keys(modparts);
    partnoffset=0;
    parteloffset=0;
    for pkey = partskeys
        part=modparts(pkey{1});
        part.noffset=partnoffset;
        part.eloffset=parteloffset;
        part.nlength=size(part.nodes,2);
        part.ellength=size(part.elements,2);
        modparts(pkey{1})=part;
        partnoffset=partnoffset+part.nlength;
        parteloffset=parteloffset+part.ellength;
    end
    nnodes=partnoffset;
    nelements=parteloffset;
    
    nodes=zeros(3,nnodes);
    elements=zeros(g_element_num,nelements);
    materials=zeros(2,nelements);
    fix=[];
    act_con=[];
    act_value=[];
    
    for pkey = partskeys
        part=modparts(pkey{1});
        nodes(:,part.noffset+1:part.noffset+part.nlength)=part.nodes;
        elements(:,part.eloffset+1:part.eloffset+part.ellength)=part.elements+part.noffset;
        for section=part.sections
            elindex=part.elset(section.elset)+part.eloffset;
            secmat=modmaterials(section.mat);
            materials(:,elindex)=repmat([secmat.C10;secmat.D],1,size(elindex,2));
        end
    end
    
    for boundary = modboundaries
        if ~strcmp(boundary.type,'ENCASTRE')
            continue;
        end
        boundsets=modassembly.nset(boundary.set);
        for bset=boundsets
            bpartname=modassembly.instance(bset.instance);
            bpart=modparts(bpartname);
            bnset=bset.nset';
            fix=[fix;bnset+bpart.noffset];
        end
    end
    
    for mload=modloads
        ltype=mload.type;
        if strcmp(ltype,'Dsload')
            lsurf_con=[];
            lsurfset=modassembly.surface(mload.set);
            
            lsurfS1=modassembly.elset(lsurfset('S1'));
            lsurfS1part=modparts(modassembly.instance(lsurfS1.instance));
            lsurfS1elset=lsurfS1part.elements(:,lsurfS1.elset);
            if g_surface_num==6
                s1Index=[2,1,3,5,7,6];
            elseif g_surface_num==3
                s1Index=[2,1,3];
            elseif g_surface_num==4
                s1Index=[4,3,2,1];
            elseif g_surface_num==8
                s1Index=[4,3,2,1,11,10,9,12];
            end
            lsurf_con=[lsurf_con,lsurfS1elset(s1Index,:)+lsurfS1part.noffset];
            
            lsurfS2=modassembly.elset(lsurfset('S2'));
            lsurfS2part=modparts(modassembly.instance(lsurfS2.instance));
            lsurfS2elset=lsurfS2part.elements(:,lsurfS2.elset);
            if g_surface_num==6
                s2Index=[1,2,4,5,9,8];
            elseif g_surface_num==3
                s2Index=[1,2,4];
            elseif g_surface_num==4
                s2Index=[5,6,7,8];
            elseif g_surface_num==8
                s2Index=[5,6,7,8,13,14,15,16];
            end
            lsurf_con=[lsurf_con,lsurfS2elset(s2Index,:)+lsurfS2part.noffset];
            
            lsurfS3=modassembly.elset(lsurfset('S3'));
            lsurfS3part=modparts(modassembly.instance(lsurfS3.instance));
            lsurfS3elset=lsurfS3part.elements(:,lsurfS3.elset);
            if g_surface_num==6
                s3Index=[2,3,4,6,10,9];
            elseif g_surface_num==3
                s3Index=[2,3,4];
            elseif g_surface_num==4
                s3Index=[1,2,6,5];
            elseif g_surface_num==8
                s3Index=[1,2,6,5,9,18,13,17];
            end
            lsurf_con=[lsurf_con,lsurfS3elset(s3Index,:)+lsurfS3part.noffset];
            
            lsurfS4=modassembly.elset(lsurfset('S4'));
            lsurfS4part=modparts(modassembly.instance(lsurfS4.instance));
            lsurfS4elset=lsurfS4part.elements(:,lsurfS4.elset);
            if g_surface_num==6
                s4Index=[1,4,3,8,10,7];
            elseif g_surface_num==3
                s4Index=[1,4,3];
            elseif g_surface_num==4
                s4Index=[2,3,7,6];
            elseif g_surface_num==8
                s4Index=[2,3,7,6,10,19,14,18];
            end
            lsurf_con=[lsurf_con,lsurfS4elset(s4Index,:)+lsurfS4part.noffset];
            
            if g_surface_num==4 || g_surface_num==8
                lsurfS5=modassembly.elset(lsurfset('S5'));
                lsurfS5part=modparts(modassembly.instance(lsurfS5.instance));
                lsurfS5elset=lsurfS5part.elements(:,lsurfS5.elset);
                if g_surface_num==4
                    s5Index=[3,4,8,7];
                elseif g_surface_num==8
                    s5Index=[3,4,8,7,11,20,15,19];
                end
                lsurf_con=[lsurf_con,lsurfS5elset(s5Index,:)+lsurfS5part.noffset];

                lsurfS6=modassembly.elset(lsurfset('S6'));
                lsurfS6part=modparts(modassembly.instance(lsurfS6.instance));
                lsurfS6elset=lsurfS6part.elements(:,lsurfS6.elset);
                if g_surface_num==4
                    s6Index=[1,5,8,4];
                elseif g_surface_num==8
                    s6Index=[1,5,8,4,17,16,20,12];
                end
                lsurf_con=[lsurf_con,lsurfS6elset(s6Index,:)+lsurfS6part.noffset];
            end

            act_con=[act_con,lsurf_con];
            load_value=mload.value*ones(1,size(lsurf_con,2));
            act_value=[act_value,load_value];
        end
        if strcmp(ltype,'Connector')
            lcnn_con=[];
            lcnnelset=modassembly.elset(mload.set);
            for lcnnelementindex=lcnnelset
                lcnnelement=modassembly.cnnelements(lcnnelementindex);
                lcnnnodepart1=modparts(modassembly.instance(lcnnelement.instance1));
                lcnnnode1=lcnnelement.node1+lcnnnodepart1.noffset;
                lcnnnodepart2=modparts(modassembly.instance(lcnnelement.instance2));
                lcnnnode2=lcnnelement.node2+lcnnnodepart2.noffset;
                lcnn_con=[lcnn_con,[lcnnnode1;lcnnnode2]];
            end
            act_con=[act_con,lcnn_con];
            load_value=-mload.value*ones(1,size(lcnn_con,2));
            act_value=[act_value,load_value];
        end
    end
    
    fix=unique(fix);
    nodes=nodes(:);
    elements=elements*3-2;
    fix=fix*3-2;
    act_con=act_con*3-2;
    save(fname,'nodes','elements','fix','act_con','act_value','materials');
end

function tline=NextLine(fin)
    tline=fgetl(fin);
    while strncmp(tline,'**',2)
        tline=fgetl(fin);
    end
end

function map=StrKeyValues(tline)
    map=containers.Map;
    tlinesplit=strsplit(tline,',');
    for linekv=tlinesplit
        linekv=linekv{1};
        kv=strsplit(linekv,'=');
        if size(kv,2)==2
            map(strtrim(kv{1}))=strtrim(kv{2});
        end
    end
end

function newNum=IncreNum(num)
    if numel(num)==3 && num(3)<num(2)
        newNum=(num(1):num(3):num(2));
    else
        newNum=num;
    end
    if iscolumn(newNum)
        newNum=newNum';
    end
end