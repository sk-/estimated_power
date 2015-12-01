class CircularArray {
	var data;
	var index;

	function initialize(size) {
		data = new [size];
		index = 0;
	}
	
	function add(element) {
		data[index % data.size()] = element;
		index += 1;
	}
	
	function first() {
		if (index == 0) {
			return null;
		}
		var size = data.size();
		if (index < size) {
			return data[0];
		}
		return data[index % size];
	}
	
	function last() {
		if (index == 0) {
			return null;
		}
		return data[(index - 1) % data.size()];
	}
}