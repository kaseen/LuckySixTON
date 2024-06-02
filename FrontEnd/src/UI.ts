export const bodyContainerStyle = () => {
    return {
        background: 'linear-gradient(300deg, #020024 0%, #090979 0%, #00d4ff 60%)'
    }
}

export const roundInfoStyle = () => {
    return {
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        alignItems: 'center',
    }
}

export const LOTTERY_STATE = {
    0: 'Ready',
    1: 'Started',
    2: 'Closed'
}