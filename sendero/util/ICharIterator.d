module sendero.util.ICharIterator;

public import sendero.util.IStringViewer;

interface ICharIterator(Ch) : IStringViewer!(Ch)
{
	bool good();
	Ch opIndex(size_t);
	ICharIterator!(Ch) opAddAssign(size_t i);
	ICharIterator!(Ch) opPostInc();
	ICharIterator!(Ch) opSubAssign(size_t i);
	ICharIterator!(Ch) opPostDec();
	Ch[] opSlice(size_t x, size_t y);
	size_t location();
	Ch[] randomAccessSlice(size_t x, size_t y);
	bool seek(size_t location);
	IStringViewer!(Ch) src();
}