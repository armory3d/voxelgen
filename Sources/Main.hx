package;

class Main {

	static var numverts = 0;
	static var meshData:iron.data.MeshData;

	public static function main() {
		kha.System.init({title: "Empty", width: 640, height: 480}, function() {
			iron.App.init(ready);
		});
	}

	static function toF32(ar:Array<Float>):kha.arrays.Float32Array {
		var vals = new kha.arrays.Float32Array(ar.length);
		for (i in 0...vals.length) vals[i] = ar[i];
		return vals;
	}

	static function toU32(ar:Array<Int>):kha.arrays.Uint32Array {
		var vals = new kha.arrays.Uint32Array(ar.length);
		for (i in 0...vals.length) vals[i] = ar[i];
		return vals;
	}

	static function ready() {
		iron.Scene.setActive("Scene");
		
		var path = "mesh.obj";
		#if kha_kore
		path = Sys.getCwd() + "/" + path;
		#end

		// iron.data.Data.getMesh("mesh", "", null, function(md:iron.data.MeshData) {
		iron.data.Data.getBlob(path, function(md:kha.Blob) {
			var obj = new ObjLoader(md.toString());
			
			var pa = obj.indexedVertices;
			var na = obj.indexedNormals;
			var uva = obj.indexedUVs;
			var ia = obj.indices;
			numverts = Std.int(pa.length / 3);

			var pos:TVertexArray = {
				attrib: "pos",
				size: 3,
				values: toF32(pa)
			};

			var nor:TVertexArray = {
				attrib: "nor",
				size: 3,
				values: toF32(na)
			};

			var tex:TVertexArray = {
				attrib: "tex",
				size: 2,
				values: toF32(uva)
			};

			var indices:TIndexArray = {
				material: 0,
				size: 3,
				values: toU32(ia)
			};

			var rawmesh:TMesh = {
				vertex_arrays: [pos, nor],
				index_arrays: [indices]
			};

			var rawmeshData:TMeshData = { 
				name: "Mesh",
				mesh: rawmesh 
			};

			new iron.data.MeshData(rawmeshData, function(data:iron.data.MeshData) {
				meshData = data;
			});


			iron.object.Uniforms.externalTextureLinks = [externalTextureLink];
		});
	}

	static function externalTextureLink(tulink:String):kha.Image {
		if (tulink == "_basecolor") {
			// return basecolor;
		}
		return null;
	}

	static var startTime = 0.0;
	public static function begin() {
		trace("VOX: GPU");
		startTime = kha.Scheduler.realTime();

		// set pipeline
		// set uniforms
		// set buffers
		// draw
	}

	public static function end() {
		trace("VOX: " + Std.int((kha.Scheduler.realTime() - startTime) * 10000) / 10 + "ms processing " + numverts + " vertices");
		trace("VOX: Write");
		
		var image = iron.Scene.active.camera.data.pathdata.renderTargets.get("voxels").image;
		var b = image.getPixels();

		#if kha_krom
		Krom.fileSaveBytes("out.bin", b.getData());
		#else
		sys.io.File.saveBytes("out.bin", b);
		#end

		trace("VOX: Done");
		kha.System.requestShutdown();
	}
}
