package de.upb.reconos.gui;

import java.awt.Color;
import java.awt.Cursor;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.util.Vector;

import javax.swing.JPanel;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;



public class RenderPanel extends JPanel implements MouseListener, MouseMotionListener,
		MouseWheelListener, ChangeListener {

	private static final long serialVersionUID = 1L;
	
	private Vector2d center;
	private Vector2d dragObjectOffset;
	private Vector2d baseScaleFactor;
	private int dragX;
	private int dragY;	
	private Interactable dragObject;
	private Vector<ChangeListener> changeListeners;
	private boolean antialiasing;
	
	public RenderPanel(){
		this.setBackground(Color.WHITE);
		addMouseListener(this);
		addMouseMotionListener(this);
		addMouseWheelListener(this);
		center = new Vector2d(0,0);
		dragObjectOffset = new Vector2d();
		baseScaleFactor = new Vector2d(2,-2);

		changeListeners = new Vector<ChangeListener>();
		
		setPreferredSize(new Dimension(Short.MAX_VALUE, Short.MAX_VALUE));
		setMaximumSize(new Dimension(Short.MAX_VALUE, Short.MAX_VALUE));
		
		antialiasing = true;
	}
	
	public void center(){
		center = new Vector2d(0,0);
		baseScaleFactor = new Vector2d(2,-2);
	}
	
	public void translate(double x, double y){
		center.add(x, y);
	}
	
	public void addChangeListener(ChangeListener l){
		changeListeners.add(l);
	}
	
	public void removeChangeListener(ChangeListener l){
		changeListeners.remove(l);
	}
	
	public Vector2d view2world(Vector2d view){
		Vector2d world = new Vector2d();
		world.setX((view.getX()/getScale().getX() - center.getX() - 0.5*getWidth()/getScale().getX()));
		world.setY((view.getY()/getScale().getY() - center.getY() - 0.5*getHeight()/getScale().getY()));
		return world;
	}
	
	public Vector2d world2view(Vector2d world){
		Vector2d view = new Vector2d();
		view.setX((world.getX() + center.getX() + 0.5*getWidth()/getScale().getX())*getScale().getX());
		view.setY((world.getY() + center.getY() + 0.5*getHeight()/getScale().getY())*getScale().getY());
		return view;
	}
	
	public void mouseDragged(MouseEvent e) {
		if(dragObject == null){
			if((e.getModifiers() & MouseEvent.BUTTON2_MASK) != 0){
				Vector2d w0 = view2world(new Vector2d(dragX,dragY));
				Vector2d w1 = view2world(new Vector2d(e.getX(),e.getY()));
				w1.sub(w0);
				center.add(w1);
			}
		}
		
		dragX = e.getX();
		dragY = e.getY();
		
		if((e.getModifiers() & MouseEvent.BUTTON2_MASK) != 0){
			this.invalidate();
			this.repaint();
			return;
		}
		
		Vector2d w = view2world(new Vector2d(e.getX(),e.getY()));
		if(dragObject != null){
			dragObject.dragReleased(w.getX() - dragObjectOffset.getX(),w.getY() - dragObjectOffset.getY());
		}
		this.invalidate();
		this.repaint();
	}
	
	public void mousePressed(MouseEvent e) {
		dragX = e.getX();
		dragY = e.getY();
		dragObject = null;
		
		if(e.getButton() != 1) return;
		
		Vector2d w = view2world(new Vector2d(e.getX(),e.getY()));
		
		Vector<Interactable> ia = getInteractables();
		for(int i = ia.size() - 1; i >= 0; i--){
			if(ia.get(i).isDraggable() 
			&& ia.get(i).contains(w.getX(),w.getY()))
			{
				dragObject = ia.get(i);
				dragObjectOffset = Vector2d.sub(w, 
						ia.get(i).getPosition());
				return;
			}
		}
	}
	
	protected Vector<Interactable> getInteractables(){
		return null;
	}
	
	protected Vector<Drawable> getDrawables(){
		return null;
	}
	
	public void stateChanged(ChangeEvent e){
		for(ChangeListener l : changeListeners){
			l.stateChanged(e);
		}
	}
	
	private Interactable getInteractable(int x, int y){
		Vector2d w = view2world(new Vector2d(x,y));
		Vector<Interactable> ia = getInteractables();

		for(Interactable i: ia){
			if(i.contains(w.getX(),w.getY())) return i;
		}
		return null;
	}
	
	public void mouseReleased(MouseEvent e) {
		Vector2d w = view2world(new Vector2d(e.getX(),e.getY()));
		if(dragObject != null && e.getButton() == 1){
			dragObject.dragReleased(w.getX() - dragObjectOffset.getX(),w.getY() - dragObjectOffset.getY());
		}
		dragObject = null;
	}

	public void mouseWheelMoved(MouseWheelEvent e) {
		baseScaleFactor.mul(Math.pow(1.1, -e.getWheelRotation()));
		this.invalidate();
		this.repaint();
	}
	
	public void paint(Graphics g){
		super.paint(g);
		
		Graphics2D g2d = (Graphics2D)g.create();
		
		if(antialiasing){
			g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
		}
		else{
			g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_OFF);
		}
		
		g2d.scale(getScale().getX(), getScale().getY());
		g2d.translate(center.getX() + 0.5*getWidth()/getScale().getX(),
				center.getY() + 0.5*getHeight()/getScale().getY());
		
		Vector<Drawable> drawables = getDrawables();
		if(drawables == null) return;
		
		for(Drawable d : drawables){
			d.draw(g2d);
		}
	}

	public void mouseClicked(MouseEvent e) {
		dragObject = null;
		Vector2d w = view2world(new Vector2d(e.getX(),e.getY()));
		
		Interactable ia = getInteractable(e.getX(),e.getY());
		
		if(ia == null) return;
		
		ia.onClick(e, w.getX(), w.getY());
		
		for(ChangeListener l: changeListeners){ 
			l.stateChanged(new ChangeEvent(this));
		}
		
		this.invalidate();
		this.repaint(1);
	}
		
	public void mouseEntered(MouseEvent e) {}
	public void mouseExited(MouseEvent e) {}
	public void mouseMoved(MouseEvent e) {
		Vector<Interactable> ia = getInteractables();
		Cursor c = null;
		Vector2d w = view2world(new Vector2d(e.getX(),e.getY()));
		for(int i = ia.size() - 1; i >= 0; i--){
			if(ia.get(i).isDraggable() 
			&& ia.get(i).contains(w.getX(),w.getY()))
			{
				dragObject = ia.get(i);
				c = dragObject.getCursor();
				if(c != null){
					setCursor(c);
				}
			}
		}
		if(c == null) setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
	}

	public boolean isAntialiasing() {
		return antialiasing;
	}

	public void setAntialiasing(boolean antialiasing) {
		this.antialiasing = antialiasing;
	}
/*
	private void setZoomFactor(Vector2d zoomFactor) {
		this.zoomFactor = zoomFactor;
	}
*/
	private Vector2d getScale() {
		Vector2d z = new Vector2d(baseScaleFactor);
		z.mul(getWidth()/640.0);
		return z;
	}
}
