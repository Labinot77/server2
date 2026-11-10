const Money = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
});

export const FormatMoney = (Value) => Money.format(Number(Value) || 0);

export const TimeAgo = (Timestamp) => {
    const Time = new Date(Timestamp).getTime();
    if (Number.isNaN(Time)) return '';

    const Seconds = Math.max(0, (Date.now() - Time) / 1000);
    if (Seconds < 60) return 'just now';
    if (Seconds < 3600) return `${Math.floor(Seconds / 60)}m ago`;
    if (Seconds < 86400) return `${Math.floor(Seconds / 3600)}h ago`;
    if (Seconds < 2592000) return `${Math.floor(Seconds / 86400)}d ago`;

    return new Date(Time).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

const Titleize = (Text) => Text ? Text.charAt(0).toUpperCase() + Text.slice(1).toLowerCase() : '';

const Verbs = {
    DEPOSIT: 'Deposited',
    WITHDRAW: 'Withdrawn',
    TRANSFER: 'Transferred',
};

export const TransactionVerb = (Type, IsNegative) => {
    const Key = String(Type || '').toUpperCase();
    return Verbs[Key] || Titleize(Key) || (IsNegative ? 'Withdrawn' : 'Deposited');
};

// "transfers" | "withdrawals" | "deposits" — used by the history filter chips
export const TransactionKind = (Transaction) => {
    if (String(Transaction.TransactionType).toUpperCase() == 'TRANSFER') return 'transfers';
    return Transaction.IsNegative ? 'withdrawals' : 'deposits';
};
