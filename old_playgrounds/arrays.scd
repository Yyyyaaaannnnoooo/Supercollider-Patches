[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].sputter(0.5, 16).postln;
Array.fill([2, 2, 3], { arg i, j, k;  i * 100 + (j * 10) + k });
Array.fill(10, { arg i; 2 ** i });

Array.newFrom(Set[4, 2, 1]);

Array.geom(5, 1, 3).postln;

Array.interpolation(5, 3.2, 20.5);

// Array.rand(size, minVal, maxVal);
Array.rand(8, 1, 100);

// Array.linrand(size, minVal, maxVal);
Array.linrand(8, 1, 100);

// Array.exprand(size, minVal, maxVal);
Array.exprand(8, 1, 100);

(
// z and y are the same object
var y, z;
z = [1, 2, 3];
y = z.add(4);
z.postln;
y.postln;
)