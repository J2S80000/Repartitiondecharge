rsconf = {
    _id: "replSet_a",
    members: [
        { _id: 0, host: "principal_a:27017" },
        { _id: 1, host: "secondaire_a_1:27017" },
        { _id: 2, host: "secondaire_a_2:27017" },
        { _id: 3, host: "secondaire_a_3:27017" }
    ]
};

rs.initiate(rsconf);
rs.conf();