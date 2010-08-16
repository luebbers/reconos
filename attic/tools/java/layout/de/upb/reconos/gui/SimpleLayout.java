package de.upb.reconos.gui;

import java.awt.Component;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.LayoutManager;

public abstract class SimpleLayout implements LayoutManager {

	public void addLayoutComponent(String name, Component comp) {
		//System.out.println("RowLayout.addLayoutComponent(" + name + "," + comp + ")");
	}

	public abstract void layoutContainer(Container parent);

	public Dimension minimumLayoutSize(Container parent) {
		//System.out.println("RowLayout.minimumLayoutSize(" + parent + ")");
		return preferredLayoutSize(parent);
	}

	public abstract Dimension preferredLayoutSize(Container parent);

	public void removeLayoutComponent(Component comp) {
		//System.out.println("RowLayout.removeLayoutComponent(" + comp + ")");
	}
}
