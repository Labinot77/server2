'use strict';

// Radial menu engine ported from codera-radialmenu, adapted to fw-menu's
// item format: { Id, Title, Icon: '#fa-symbol-id', Items, Event, Type, Parameters, Close }

var DEFAULT_SIZE = 150;
var SVG_NS = 'http://www.w3.org/2000/svg';
var XLINK_NS = 'http://www.w3.org/1999/xlink';

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function RadialMenu(params) {
    var self = this;

    self.parent    = params.parent  || document.body;
    self.size      = params.size    || DEFAULT_SIZE;
    self.onClick   = params.onClick || null;
    self.onClose   = params.onClose || null;
    self.menuItems = Array.isArray(params.menuItems) ? params.menuItems : [];

    self.radius      = 55;
    self.innerRadius = 23.5;
    self.sectorSpace = 2.35;
    self.sectorCount = Math.max(self.menuItems.length, 1);
    self.itemDensity = 1;

    self.holder      = null;
    self.parentMenu  = [];
    self.parentItems = [];
    self.levelItems  = null;
    self.navigationVersion = 0;
    self.isEntering  = false;
    self.isReturning = false;
    self.destroyed   = false;
    self.closed      = false;

    self.createHolder();
    self.holder.addEventListener('contextmenu', function (event) {
        event.preventDefault();
        self.handleCenterClick();
    });

    self.currentMenu = null;
    self.boundOnMouseWheel = self.onMouseWheel.bind(self);
    self.boundOnKeyDown = self.onKeyDown.bind(self);
    document.addEventListener('wheel', self.boundOnMouseWheel);
    document.addEventListener('keydown', self.boundOnKeyDown);
}

// fw-menu sends Lua tables; sparse tables can arrive as objects ({"1":..,"9":..}).
RadialMenu.toArray = function (items) {
    if (Array.isArray(items)) return items.filter(function (i) { return i != null; });
    if (items && typeof items === 'object') {
        return Object.keys(items)
            .sort(function (a, b) { return Number(a) - Number(b); })
            .map(function (k) { return items[k]; })
            .filter(function (i) { return i != null; });
    }
    return [];
};

RadialMenu.hasChildren = function (item) {
    return !!item && RadialMenu.toArray(item.Items).length > 0;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.open = function () {
    var self = this;
    self.closed = false;
    self.holder.classList.add('is-open');
    self.setControlAction('CLOSE');
    if (!self.currentMenu) {
        var openingMenu = self.createMenu('menu inner', self.menuItems);
        self.currentMenu = openingMenu;
        self.holder.appendChild(openingMenu);
        var navigationVersion = self.navigationVersion;

        RadialMenu.nextTick(function () {
            if (self.destroyed || navigationVersion !== self.navigationVersion || self.currentMenu !== openingMenu) return;
            openingMenu.setAttribute('class', 'menu');
        });
    }
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// silent = true: animate out without notifying Lua (used when Lua already asked us to close)
RadialMenu.prototype.close = function (silent) {
    var self = this;
    if (self.closed) return self.closingPromise || Promise.resolve();
    self.closed = true;
    self.holder.classList.remove('is-open');
    self.setControlAction('CLOSE');

    if (!self.currentMenu) {
        self.closingPromise = Promise.resolve();
        if (!silent && self.onClose) self.onClose();
        return self.closingPromise;
    }

    ++self.navigationVersion;
    self.isEntering = false;
    self.isReturning = false;
    var closingMenu = self.currentMenu;
    self.currentMenu = null;
    self.levelItems = null;
    var parentMenu;
    while (parentMenu = self.parentMenu.pop()) {
        parentMenu.remove();
    }
    self.parentItems = [];

    self.closingPromise = RadialMenu.setClassAndWaitForTransition(closingMenu, 'menu inner').then(function () {
        closingMenu.remove();
    });
    if (!silent && self.onClose) self.onClose();
    return self.closingPromise;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.destroy = function () {
    var self = this;
    self.destroyed = true;
    self.closed = true;
    ++self.navigationVersion;
    self.isEntering = false;
    self.isReturning = false;
    document.removeEventListener('wheel', self.boundOnMouseWheel);
    document.removeEventListener('keydown', self.boundOnKeyDown);
    if (self.holder) self.holder.remove();
    self.currentMenu = null;
    self.parentMenu = [];
    self.parentItems = [];
    self.levelItems = null;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.getParentMenu = function () {
    var self = this;
    return self.parentMenu.length > 0 ? self.parentMenu[self.parentMenu.length - 1] : null;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.createHolder = function () {
    var self = this;

    self.holder = document.createElement('div');
    self.holder.className = 'menuHolder';
    self.holder.style.width  = self.size + 'px';
    self.holder.style.height = self.size + 'px';

    var controls = document.createElement('div');
    controls.className = 'radial-controls';
    controls.innerHTML =
        '<img class="mouse-hint" src="img/mouse_left_outline.png" alt="">' +
        '<span>SELECT</span>' +
        '<span class="radial-controls__divider"></span>' +
        '<img class="mouse-hint" src="img/mouse_right_outline.png" alt="">' +
        '<span class="radial-controls__action">CLOSE</span>';
    self.holder.appendChild(controls);

    self.parent.appendChild(self.holder);
};

RadialMenu.prototype.setControlAction = function (label) {
    var action = this.holder && this.holder.querySelector('.radial-controls__action');
    if (action) action.textContent = label;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.showNestedMenu = function (item) {
    var self = this;
    if (self.destroyed || self.isEntering || self.isReturning || !self.currentMenu || !RadialMenu.hasChildren(item)) return;

    self.isEntering = true;
    self.setControlAction('BACK');
    var parentMenu = self.currentMenu;
    self.parentMenu.push(parentMenu);
    self.parentItems.push(self.levelItems);
    var nestedMenu = self.createMenu('menu inner', item.Items, true);
    self.currentMenu = nestedMenu;
    self.holder.appendChild(nestedMenu);
    var navigationVersion = ++self.navigationVersion;

    RadialMenu.nextTick(function () {
        if (self.destroyed || navigationVersion !== self.navigationVersion || self.currentMenu !== nestedMenu) return;
        parentMenu.setAttribute('class', 'menu outer');
        nestedMenu.setAttribute('class', 'menu');
        self.isEntering = false;
    });
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.returnToParentMenu = function () {
    var self = this;
    var parentMenu = self.getParentMenu();
    if (self.destroyed || self.isReturning || !self.currentMenu || !parentMenu) return;

    self.isEntering = false;
    self.isReturning = true;
    var leavingMenu = self.currentMenu;
    var navigationVersion = ++self.navigationVersion;
    parentMenu.setAttribute('class', 'menu');

    RadialMenu.setClassAndWaitForTransition(leavingMenu, 'menu inner').then(function () {
        if (self.destroyed || navigationVersion !== self.navigationVersion) return;
        leavingMenu.remove();
        self.parentMenu.pop();
        self.currentMenu = parentMenu;
        self.levelItems = self.parentItems.pop();
        self.setControlAction(self.parentItems.length > 0 ? 'BACK' : 'CLOSE');
        self.isReturning = false;
    });
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.handleClick = function (index) {
    var self = this;
    if (!self.levelItems) return;

    var selectedIndex = index !== undefined ? index - 1 : self.getSelectedIndex();
    if (selectedIndex < 0) return;

    var item = self.levelItems[selectedIndex];
    if (item == null) return;

    if (RadialMenu.hasChildren(item)) {
        self.showNestedMenu(item);
    } else if (self.onClick) {
        self.onClick(item);
    }
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.handleCenterClick = function () {
    var self = this;
    if (self.parentItems.length > 0) {
        self.returnToParentMenu();
    } else {
        self.close();
    }
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.createCenter = function (svg, title) {
    var self = this;
    var g = document.createElementNS(SVG_NS, 'g');
    g.setAttribute('class', title === 'MENU' ? 'center center--menu' : 'center');

    g.appendChild(self.createCircle(0, 0, self.innerRadius - self.sectorSpace));

    var text = self.createText(0, 0, title);
    text.setAttribute('dominant-baseline', 'central');
    text.setAttribute('alignment-baseline', 'central');
    g.appendChild(text);

    svg.appendChild(g);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.createMenu = function (classValue, levelItems, nested) {
    var self = this;

    self.levelItems = RadialMenu.toArray(levelItems);
    self.sectorCount = Math.max(self.levelItems.length, 1);
    self.itemDensity = Math.max(0.68, Math.min(1, 8 / self.sectorCount));

    var svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('class', classValue);
    svg.setAttribute('viewBox', '-50 -50 100 100');
    svg.setAttribute('width', self.size);
    svg.setAttribute('height', self.size);
    svg.setAttribute('data-count', self.levelItems.length);
    svg.style.setProperty('--item-font-size', RadialMenu.numberToString(3.05 * self.itemDensity) + 'px');

    var angleStep = 360 / self.sectorCount;
    var gapAngle = self.levelItems.length > 1 ? Math.min(3.4, angleStep * 0.1) : 0;

    for (var i = 0; i < self.levelItems.length; ++i) {
        var centerAngle = 180 - angleStep * i;
        var startAngle = centerAngle - angleStep / 2 + gapAngle / 2;
        var endAngle = centerAngle + angleStep / 2 - gapAngle / 2;
        self.appendSectorPath(startAngle, endAngle, svg, self.levelItems[i], i);
    }

    self.createWheelRings(svg);
    self.createSelectionArc(svg);
    self.createCenter(svg, nested ? 'BACK' : 'MENU');
    self.createCenterSelectionArc(svg);
    self.updateSelectionArc(svg);

    svg.addEventListener('mousedown', function (event) {
        var target = event.target.closest('g.sector');
        if (target && svg.contains(target)) {
            var index = parseInt(target.getAttribute('data-index'));
            if (!isNaN(index)) self.setSelectedIndex(index);
        }
    });

    svg.addEventListener('pointermove', function (event) {
        var target = event.target.closest('g.sector');
        if (!target || !svg.contains(target)) return;
        var index = parseInt(target.getAttribute('data-index'));
        if (!isNaN(index) && index !== self.getSelectedIndex()) self.setSelectedIndex(index);
    });

    svg.addEventListener('click', function (event) {
        var sector = event.target.closest('g.sector');
        var center = event.target.closest('g.center');
        if (sector && svg.contains(sector)) {
            self.handleClick();
        } else if (center && svg.contains(center)) {
            self.handleCenterClick();
        }
    });
    return svg;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.selectDelta = function (indexDelta) {
    var self = this;
    if (!self.levelItems || self.levelItems.length === 0) return;
    var selectedIndex = Math.max(self.getSelectedIndex(), 0) + indexDelta;
    var len = self.levelItems.length;
    selectedIndex = ((selectedIndex % len) + len) % len;
    self.setSelectedIndex(selectedIndex);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.onKeyDown = function (event) {
    var self = this;
    if (!self.currentMenu) return;
    switch (event.key) {
        case 'Escape':
        case 'Backspace':
            self.handleCenterClick();
            event.preventDefault();
            break;
        case 'Enter':
            self.handleClick();
            event.preventDefault();
            break;
        case 'ArrowRight':
        case 'ArrowUp':
            self.selectDelta(1);
            event.preventDefault();
            break;
        case 'ArrowLeft':
        case 'ArrowDown':
            self.selectDelta(-1);
            event.preventDefault();
            break;
        case '1': case '2': case '3': case '4': case '5':
        case '6': case '7': case '8': case '9':
            self.handleClick(parseInt(event.key));
            break;
    }
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.onMouseWheel = function (event) {
    var self = this;
    if (self.currentMenu) self.selectDelta(-event.deltaY > 0 ? 1 : -1);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.getSelectedNode = function () {
    return this.currentMenu ? this.currentMenu.querySelector('g.sector.selected') : null;
};

RadialMenu.prototype.getSelectedIndex = function () {
    var selectedNode = this.getSelectedNode();
    return selectedNode ? parseInt(selectedNode.getAttribute('data-index')) : -1;
};

RadialMenu.prototype.setSelectedIndex = function (index) {
    var self = this;
    if (!self.currentMenu || !self.levelItems || index < 0 || index >= self.levelItems.length) return;
    var itemToSelect = self.currentMenu.querySelector('g.sector[data-index="' + index + '"]');
    if (!itemToSelect) return;
    self.currentMenu.querySelectorAll('g.sector.selected').forEach(function (node) {
        node.classList.remove('selected');
    });
    itemToSelect.classList.add('selected');
    self.updateSelectionArc(self.currentMenu);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.createWheelRings = function (svg) {
    var edge = this.createCircle(0, 0, this.radius + 0.15);
    edge.setAttribute('class', 'wheel-ring wheel-ring--edge');
    svg.appendChild(edge);

    var outer = this.createCircle(0, 0, this.radius + 2.25);
    outer.setAttribute('class', 'wheel-ring wheel-ring--outer');
    svg.appendChild(outer);
};

RadialMenu.prototype.createSelectionArc = function (svg) {
    var arc = document.createElementNS(SVG_NS, 'path');
    arc.setAttribute('class', 'selection-arc');
    svg.appendChild(arc);
};

RadialMenu.prototype.createCenterSelectionArc = function (svg) {
    var arc = document.createElementNS(SVG_NS, 'path');
    arc.setAttribute('class', 'center-selection-arc');
    svg.appendChild(arc);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.updateSelectionArc = function (svg) {
    if (!svg) return;

    var selected = svg.querySelector('g.sector.selected');
    var arc = svg.querySelector('path.selection-arc');
    var centerArc = svg.querySelector('path.center-selection-arc');
    if (!selected || !arc || !centerArc) return;

    var startAngle = parseFloat(selected.getAttribute('data-start-angle'));
    var endAngle = parseFloat(selected.getAttribute('data-end-angle'));
    var radius = this.innerRadius + 0.05;
    var centerRadius = this.innerRadius - this.sectorSpace;
    var angleSize = Math.abs(endAngle - startAngle);

    if (angleSize >= 359.99) {
        arc.setAttribute('d', RadialMenu.fullCircle(radius));
        centerArc.setAttribute('d', RadialMenu.fullCircle(centerRadius));
        return;
    }

    var largeArc = angleSize > 180 ? 1 : 0;
    arc.setAttribute('d', 'M' + RadialMenu.pointToString(RadialMenu.getDegreePos(endAngle, radius)) +
        'A' + radius + ' ' + radius + ' 0 ' + largeArc + ' 1 ' + RadialMenu.pointToString(RadialMenu.getDegreePos(startAngle, radius)));
    centerArc.setAttribute('d', 'M' + RadialMenu.pointToString(RadialMenu.getDegreePos(endAngle, centerRadius)) +
        'A' + centerRadius + ' ' + centerRadius + ' 0 ' + largeArc + ' 1 ' + RadialMenu.pointToString(RadialMenu.getDegreePos(startAngle, centerRadius)));
};

RadialMenu.fullCircle = function (r) {
    return 'M0 ' + r + 'A' + r + ' ' + r + ' 0 1 0 0 ' + (-r) + 'A' + r + ' ' + r + ' 0 1 0 0 ' + r;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// fw-menu icons are Font Awesome symbols declared in ui.html (<i data-fa-symbol="...">), referenced as "#id".
RadialMenu.prototype.createIcon = function (x, y, icon, parent) {
    var href = String(icon);
    if (href.charAt(0) !== '#') href = '#' + href;
    if (!document.getElementById(href.slice(1))) {
        console.error('[fw-menu] Icon "' + href + '" not found, using fallback.');
        href = '#more';
    }

    var size = 10 * this.itemDensity;
    var use = document.createElementNS(SVG_NS, 'use');
    use.setAttribute('x', RadialMenu.numberToString(x - size / 2));
    use.setAttribute('y', RadialMenu.numberToString(y - size * 0.8));
    use.setAttribute('width', RadialMenu.numberToString(size));
    use.setAttribute('height', RadialMenu.numberToString(size));
    use.setAttribute('href', href);
    use.setAttributeNS(XLINK_NS, 'xlink:href', href);
    use.setAttribute('class', 'sector-icon');
    use.setAttribute('data-index', parent.getAttribute('data-index'));
    return use;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.appendSectorPath = function (startAngleDeg, endAngleDeg, svg, item, index) {
    var self = this;
    var centerPoint = self.getSectorCenter(startAngleDeg, endAngleDeg);

    var g = document.createElementNS(SVG_NS, 'g');
    g.setAttribute('data-start-angle', startAngleDeg);
    g.setAttribute('data-end-angle', endAngleDeg);

    var path = document.createElementNS(SVG_NS, 'path');
    path.setAttribute('d', self.createSectorCmds(startAngleDeg, endAngleDeg));
    g.appendChild(path);

    if (item) {
        g.setAttribute('class', index === 0 ? 'sector selected' : 'sector');
        g.setAttribute('data-id', item.Id);
        g.setAttribute('data-index', index);
        g.addEventListener('mouseenter', function () {
            self.setSelectedIndex(index);
        });

        if (item.Title) {
            var text = self.createText(centerPoint.x, centerPoint.y, item.Title);
            text.setAttribute('transform', item.Icon
                ? 'translate(0,' + RadialMenu.numberToString(5 * self.itemDensity) + ')'
                : 'translate(0,2)');
            g.appendChild(text);
        }

        if (item.Icon) {
            var icon = self.createIcon(centerPoint.x, centerPoint.y, item.Icon, g);
            if (!item.Title) icon.setAttribute('y', RadialMenu.numberToString(centerPoint.y - 5));
            g.appendChild(icon);
        }
    } else {
        g.setAttribute('class', 'dummy');
    }

    svg.appendChild(g);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.createSectorCmds = function (startAngleDeg, endAngleDeg) {
    var self = this;
    var R = self.radius, r = self.innerRadius;

    if (Math.abs(endAngleDeg - startAngleDeg) >= 359.99) {
        return 'M0 ' + R +
            'A' + R + ' ' + R + ' 0 1 0 0 ' + (-R) +
            'A' + R + ' ' + R + ' 0 1 0 0 ' + R +
            'L0 ' + r +
            'A' + r + ' ' + r + ' 0 1 1 0 ' + (-r) +
            'A' + r + ' ' + r + ' 0 1 1 0 ' + r + 'Z';
    }

    var largeArc = Math.abs(endAngleDeg - startAngleDeg) > 180 ? 1 : 0;
    return 'M' + RadialMenu.pointToString(RadialMenu.getDegreePos(startAngleDeg, R)) +
        'A' + R + ' ' + R + ' 0 ' + largeArc + ' 0 ' + RadialMenu.pointToString(RadialMenu.getDegreePos(endAngleDeg, R)) +
        'L' + RadialMenu.pointToString(RadialMenu.getDegreePos(endAngleDeg, r)) +
        'A' + r + ' ' + r + ' 0 ' + largeArc + ' 1 ' + RadialMenu.pointToString(RadialMenu.getDegreePos(startAngleDeg, r)) +
        'Z';
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.prototype.createText = function (x, y, title) {
    var text = document.createElementNS(SVG_NS, 'text');
    text.setAttribute('text-anchor', 'middle');
    text.setAttribute('x', RadialMenu.numberToString(x));
    text.setAttribute('y', RadialMenu.numberToString(y));
    text.textContent = String(title).toUpperCase();
    return text;
};

RadialMenu.prototype.createCircle = function (x, y, r) {
    var circle = document.createElementNS(SVG_NS, 'circle');
    circle.setAttribute('cx', RadialMenu.numberToString(x));
    circle.setAttribute('cy', RadialMenu.numberToString(y));
    circle.setAttribute('r', r);
    return circle;
};

RadialMenu.prototype.getSectorCenter = function (startAngleDeg, endAngleDeg) {
    var self = this;
    return RadialMenu.getDegreePos((startAngleDeg + endAngleDeg) / 2, self.innerRadius + (self.radius - self.innerRadius) / 2);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RadialMenu.getDegreePos = function (angleDeg, length) {
    return {
        x: Math.sin(RadialMenu.degToRad(angleDeg)) * length,
        y: Math.cos(RadialMenu.degToRad(angleDeg)) * length
    };
};

RadialMenu.pointToString = function (point) {
    return RadialMenu.numberToString(point.x) + ' ' + RadialMenu.numberToString(point.y);
};

RadialMenu.numberToString = function (n) {
    if (Number.isInteger(n)) return n.toString();
    if (!n) return '0';
    var r = (+n).toFixed(5);
    if (r.match(/\./)) r = r.replace(/\.?0+$/, '');
    return r;
};

RadialMenu.degToRad = function (deg) {
    return deg * (Math.PI / 180);
};

RadialMenu.setClassAndWaitForTransition = function (node, newClass) {
    return new Promise(function (resolve) {
        if (!node || node.getAttribute('class') === newClass) {
            resolve();
            return;
        }

        var finished = false;
        var fallbackTimer;

        function finish() {
            if (finished) return;
            finished = true;
            clearTimeout(fallbackTimer);
            node.removeEventListener('transitionend', handler);
            node.removeEventListener('transitioncancel', finish);
            resolve();
        }

        function handler(event) {
            if (event.target === node && event.propertyName === 'transform') finish();
        }

        node.addEventListener('transitionend', handler);
        node.addEventListener('transitioncancel', finish);
        node.setAttribute('class', newClass);
        fallbackTimer = setTimeout(finish, 260);
    });
};

RadialMenu.nextTick = function (fn) {
    setTimeout(fn, 10);
};
