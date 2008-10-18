module sendero.session.Render;

void render_(SessionT)(IRenderable view)
{
	SessionT.req.render(view);
}