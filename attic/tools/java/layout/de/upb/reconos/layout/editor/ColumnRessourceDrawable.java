package de.upb.reconos.layout.editor;
import java.awt.Graphics2D;

import de.upb.reconos.fpga.ColumnRessource;
import de.upb.reconos.gui.LineDrawable;
import de.upb.reconos.gui.TextBlock;
import de.upb.reconos.gui.Vector2d;

public class ColumnRessourceDrawable extends LineDrawable {
	private TextBlock text;
	private ColumnRessource columnRessource;
	
//	public ColumnRessourceDrawable(int x, int ymin, int ymax, Color c, float lineWidth) {
//		super(new Vector2d(x,ymin + lineWidth), new Vector2d(x,ymax - lineWidth), c, lineWidth);
//		text = new TextBlock(new Vector2d(x,0.5*(ymin + ymax)));
//		text.font = text.font.deriveFont(ymax - ymin);
//	}
	
	public ColumnRessourceDrawable(ColumnRessource r, float lineWidth) {
		super(new Vector2d(r.slice_x,r.slice_y_min + lineWidth),
		      new Vector2d(r.slice_x,r.slice_y_max - lineWidth), r.color, lineWidth);
		//text = new TextBlock(new Vector2d(r.slice_x + 2 - lineWidth/2,0.5*(r.slice_y_min + r.slice_y_max) + lineWidth*4));
		text = new TextBlock(new Vector2d(r.slice_x ,0.5*(r.slice_y_min + r.slice_y_max)));
		//text.font = text.font.deriveFont(lineWidth*(r.slice_y_max - r.slice_y_min)*0.05f);
		text.scale = 0.1;
		text.alignment = TextBlock.ALIGN_LEFT;
		text.rotation = Math.PI/2;
		text.setText(r.toString());
		columnRessource = r;
	}
	
	
	public void draw(Graphics2D g2d) {
		super.draw(g2d);
		text.draw(g2d);
	}
}
