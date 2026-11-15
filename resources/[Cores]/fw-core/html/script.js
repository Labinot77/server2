const status = document.getElementById('status');
const pct = document.getElementById('pct');
const fill = document.getElementById('fill');

const setProgress = f => {
    const p = Math.round(f * 100);
    pct.textContent = p + '%';
    fill.style.width = p + '%';
};

const labels = {
    startInitFunctionOrder: 'INITIALIZING',
    startDataFileEntries: 'LOADING DATA FILES',
    performMapLoadFunction: 'LOADING MAP',
    onDataFileEntry: 'LOADING ASSETS'
};

window.addEventListener('message', ({ data: d }) => {
    if (d.eventName === 'loadProgress') setProgress(d.loadFraction);
    if (labels[d.eventName]) status.textContent = labels[d.eventName];
    if (d.eventName === 'onLogLine') status.textContent = d.message.replace(/\.+$/, '').toUpperCase();
});
