package de.upb.reconos.grasp.gui;


import java.awt.Font;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.io.IOException;
import java.util.Collections;
import java.util.Vector;

import javax.swing.BoxLayout;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTree;
import javax.swing.tree.DefaultMutableTreeNode;
import javax.swing.tree.DefaultTreeCellRenderer;
import javax.swing.tree.TreePath;

import de.upb.reconos.grasp.io.LibraryReader;
import de.upb.reconos.grasp.logic.Function;
import de.upb.reconos.grasp.logic.Library;
import de.upb.reconos.grasp.logic.Type;


public class LibraryBrowser extends JPanel implements MouseListener {

	private static final long serialVersionUID = 1L;
	JTree tree;
	DefaultMutableTreeNode rootNode;
	
	@SuppressWarnings("unchecked")
	public LibraryBrowser(){
		rootNode = new DefaultMutableTreeNode("Repository");
		tree = new JTree(rootNode);
		tree.setShowsRootHandles(true);
		Font f = tree.getFont();
		tree.setFont(new Font("monospaced",0,f.getSize()));
		
		DefaultTreeCellRenderer renderer = new DefaultTreeCellRenderer();
		renderer.setLeafIcon(null);
		tree.setCellRenderer(renderer);
		
		tree.addMouseListener(this);
		
		LibraryReader libReader = new LibraryReader();
		try {
			libReader.read("/home/andreas/workspace/graphys/stdlib.bar");
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		Vector<Library> libs = libReader.getLibraries();
		Collections.sort(libs);
		for(Library l : libs){
			
			addLibrary(l);
		}
		
		tree.expandRow(0);

		setLayout(new BoxLayout(this,BoxLayout.X_AXIS));
		add(new JScrollPane(tree));
	}
	
	public void addLibrary(Library lib){
		DefaultMutableTreeNode libNode = new DefaultMutableTreeNode(lib);
		for(Type t : lib.getTypes()){
			HTMLView v = new HTMLView("&nbsp;<b><font size=\"+1\">T </font></b>",t);
			libNode.add(new DefaultMutableTreeNode(v));
		}
		for(Function f : lib.getFunctions()){
			HTMLView v = new HTMLFunctionView("&nbsp;<b><font size=\"+1\">F </font></b>",f);
			libNode.add(new DefaultMutableTreeNode(v));
		}
		rootNode.add(libNode);
	}
	
	public void mouseClicked(MouseEvent e) {}
	public void mouseEntered(MouseEvent e) {}
	public void mouseExited(MouseEvent e) {}
	public void mousePressed(MouseEvent e) {
		int selRow = tree.getRowForLocation(e.getX(), e.getY());
		TreePath selPath = tree.getPathForLocation(e.getX(), e.getY());
		if(selRow != -1) {
			DefaultMutableTreeNode n = (DefaultMutableTreeNode)selPath.getLastPathComponent();
			System.err.println("node: " + n.getUserObject());
		}
	}
	public void mouseReleased(MouseEvent e) {}
}
