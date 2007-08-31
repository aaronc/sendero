module sendero.util.IStringViewer;

interface IStringViewer(Ch)
{
	Ch[] randomAccessSlice(size_t x, size_t y);
}