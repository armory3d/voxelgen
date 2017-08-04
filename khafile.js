let project = new Project('voxelgen');

project.addSources('Sources');
project.addShaders('Shaders');
project.addLibrary('iron');
project.addAssets('Assets/**');
project.addDefine('arm_json');

resolve(project);
