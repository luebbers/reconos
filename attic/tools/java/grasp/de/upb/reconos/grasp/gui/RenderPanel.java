package de.upb.reconos.grasp.gui;


import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.io.Serializable;
import java.util.Vector;

import javax.swing.JPanel;

import de.upb.reconos.grasp.gui.menus.DefaultMenu;
import de.upb.reconos.grasp.gui.menus.PortMenu;
import de.upb.reconos.grasp.gui.menus.SignalMenu;
import de.upb.reconos.grasp.gui.menus.StateMachineMenu;
import de.upb.reconos.grasp.gui.menus.StateMenu;
import de.upb.reconos.grasp.interfaces.Drawable;
import de.upb.reconos.grasp.interfaces.Interactable;
import de.upb.reconos.grasp.math.Vector2d;
import de.upb.reconos.grasp.objects.PortNode;
import de.upb.reconos.grasp.objects.SignalNode;
import de.upb.reconos.grasp.objects.StateMachineNode;
import de.upb.reconos.grasp.objects.StateNode;
import de.upb.reconos.grasp.objects.World;


public class RenderPanel extends JPanel
		implements MouseListener, MouseMotionListener, MouseWheelListener,
		KeyListener, Task, Serializable
{

	private static final long serialVersionUID = 1L;
	public double zoomFactor;
	public Vector2d center;
	private World world;
	private Interactable dragObject;
	private Vector2d dragObjectOffset;
	private int dragX;
	private int dragY;
	private DefaultMenu defaultMenu;
	private StateMenu stateMenu;
	private SignalMenu signalMenu;
	private PortMenu portMenu;
	private StateMachineMenu stateMachineMenu;
	
	public RenderPanel(World w){
		world = w;
		zoomFactor = 0.5;
		center = new Vector2d(0,0);
		setBackground(Color.WHITE);
		addMouseListener(this);
		addMouseMotionListener(this);
		addMouseWheelListener(this);
		addKeyListener(this);
		this.setFocusable(true);
		defaultMenu = new DefaultMenu(world);
		stateMenu = new StateMenu(world);
		signalMenu = new SignalMenu(world);
		portMenu = new PortMenu(world); 
		stateMachineMenu = new StateMachineMenu(world);
		startThread();
	}
	
	public void startThread(){
		(new SimpleTimer(this,40)).start();
	}
	
	public void paint(Graphics g) {
		super.paint(g);
		Graphics2D g2d = (Graphics2D)g;
		g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
				RenderingHints.VALUE_ANTIALIAS_ON);
		
		g2d.scale(zoomFactor, zoomFactor);
		g2d.translate(center.getX() + 0.5*getWidth()/zoomFactor, center.getY() + 0.5*getHeight()/zoomFactor);
		
		for(Drawable d : world.getDrawables()){
			d.draw(g2d);
		}
	}
	
	public Vector2d view2world(Vector2d view){
		Vector2d world = new Vector2d();
		world.setX((view.getX()/zoomFactor - center.getX() - 0.5*getWidth()/zoomFactor));
		world.setY((view.getY()/zoomFactor - center.getY() - 0.5*getHeight()/zoomFactor));
		return world;
	}
	
	public Vector2d world2view(Vector2d world){
		Vector2d view = new Vector2d();
		view.setX((world.getX() + center.getX() + 0.5*getWidth()/zoomFactor)*zoomFactor);
		view.setY((world.getY() + center.getY() + 0.5*getHeight()/zoomFactor)*zoomFactor);
		return view;
	}

	public synchronized void mouseClicked(MouseEvent e) {
		Vector2d w = view2world(new Vector2d(e.getX(),e.getY()));
		Interactable i = world.getInteractable(w.getX(), w.getY());
		
		if(e.getButton() == 1 && i != null){
			i.onClick(e.getButton(), w.getX(), w.getY());
			return;
		}
		
		if(e.getButton() == 2 && i != null){
			i.onClick(e.getButton(), w.getX(), w.getY());
			return;
		}
		
		if(e.getButton() == 3){
			Interactable ia = world.getInteractable(w.getX(), w.getY());
			if(ia == null){
				defaultMenu.setWorldPosition(w.getX(), w.getY());
				defaultMenu.show(this, e.getX(), e.getY());
				return;
			}
			if(ia instanceof StateNode){
				stateMenu.setStateNode((StateNode)ia);
				stateMenu.setWorldPosition(w.getX(), w.getY());
				stateMenu.show(this, e.getX(), e.getY());
				return;
			}
			if(ia instanceof SignalNode){
				signalMenu.setSignalNode((SignalNode)ia);
				signalMenu.setWorldPosition(w.getX(), w.getY());
				signalMenu.show(this, e.getX(), e.getY());
				return;
			}
			if(ia instanceof PortNode){
				portMenu.setPortNode((PortNode)ia);
				portMenu.setWorldPosition(w.getX(), w.getY());
				portMenu.show(this, e.getX(), e.getY());
				return;
			}
			if(ia instanceof StateMachineNode) {
				stateMachineMenu.setStateMachineNode((StateMachineNode)ia);
				stateMachineMenu.setWorldPosition(w.getX(), w.getY());
				stateMachineMenu.show(this, e.getX(), e.getY());
			}
		}
	}

	public synchronized void mouseDragged(MouseEvent e) {
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
	}
	
	public synchronized void mousePressed(MouseEvent e) {
		dragX = e.getX();
		dragY = e.getY();
		
		if(e.getButton() != 1) return;
		Vector2d w = view2world(new Vector2d(e.getX(),e.getY()));
		
		Vector<Interactable> ia = world.getInteractables();
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
	
	public synchronized void mouseReleased(MouseEvent e) {
		Vector2d w = view2world(new Vector2d(e.getX(),e.getY()));
		if(dragObject != null){
			dragObject.dragReleased(w.getX(),w.getY());
		}
		dragObject = null;
	}

	public synchronized void mouseWheelMoved(MouseWheelEvent e) {
		zoomFactor *= Math.pow(1.1, -e.getWheelRotation());
	}
	
	public synchronized void run() {
		int count = 40;
		
		for(int i = 0; i < count; i++){
			world.update(1.0/count);
			if(dragObject != null){
				Vector2d w = view2world(new Vector2d(dragX, dragY));
				Vector2d currentOffset = Vector2d.sub(w, dragObject.getPosition());
				Vector2d dragDelta = Vector2d.sub(currentOffset, dragObjectOffset);
				dragObject.dragTo(dragDelta.getX(), dragDelta.getY());
			}
		}
		
		repaint();
	}

	public synchronized void keyPressed(KeyEvent e) {}
	public synchronized void keyReleased(KeyEvent e) {}

	public void keyTyped(KeyEvent e) {}
	public void mouseEntered(MouseEvent arg0) {}
	public void mouseExited(MouseEvent arg0) {}
	public void mouseMoved(MouseEvent arg0) {}
}
